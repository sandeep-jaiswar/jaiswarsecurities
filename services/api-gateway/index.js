const { createClient } = require("@clickhouse/client")
const bcrypt = require("bcryptjs")
const cors = require("cors")
const express = require("express")
const rateLimit = require("express-rate-limit")
const helmet = require("helmet")
const Joi = require("joi")
const jwt = require("jsonwebtoken")
const Redis = require("redis")
const swaggerJsdoc = require("swagger-jsdoc")
const swaggerUi = require("swagger-ui-express")
const winston = require("winston")
const WebSocket = require("ws")
const http = require("http")
require("dotenv").config()

// Import route modules
const analyticsRoutes = require("./routes/analytics")
const backtestingRoutes = require("./routes/backtesting")
const economicRoutes = require("./routes/economic")
const marketRoutes = require("./routes/market")
const portfolioRoutes = require("./routes/portfolio")
const researchRoutes = require("./routes/research")
const screeningRoutes = require("./routes/screening")
const tradingRoutes = require("./routes/trading")

// Initialize logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
})

// Initialize ClickHouse connection
const clickhouse = createClient({
  url: process.env.CLICKHOUSE_URL || "http://localhost:8123",
  username: process.env.CLICKHOUSE_USER || "stockuser",
  password: process.env.CLICKHOUSE_PASSWORD || "stockpass123",
  database: process.env.CLICKHOUSE_DATABASE || "stockdb",
  clickhouse_settings: {
    async_insert: 1,
    wait_for_async_insert: 1,
  },
})

// Initialize Redis (with error handling)
let redis
try {
  redis = Redis.createClient({
    url: process.env.REDIS_URL,
  })

  redis.on("error", (err) => {
    logger.error("Redis connection error:", err)
  })

  redis.on("connect", () => {
    logger.info("Connected to Redis")
  })
} catch (error) {
  logger.error("Failed to create Redis client:", error)
}

// Initialize Express app
const app = express()
const server = http.createServer(app)

// Initialize WebSocket server
const wss = new WebSocket.Server({ server })

// Security middleware
app.use(helmet())
app.use(
  cors({
    origin: process.env.ALLOWED_ORIGINS?.split(",") || ["http://localhost:3001", "http://localhost:5678"],
    credentials: true,
  })
)

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
})
app.use(limiter)

// Body parsing middleware
app.use(express.json({ limit: "10mb" }))
app.use(express.urlencoded({ extended: true }))

// Swagger configuration
const swaggerOptions = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Bloomberg-style Stock Terminal API",
      version: "2.0.0",
      description: "Comprehensive API for stock screening, analytics, and trading with ClickHouse backend",
    },
    servers: [
      {
        url: `http://localhost:${process.env.API_PORT || 3000}`,
        description: "Development server",
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
    },
  },
  apis: ["./routes/*.js", "./index.js"],
}

const specs = swaggerJsdoc(swaggerOptions)
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(specs))

// Authentication middleware
// const authenticateToken = (req, res, next) => {
//   const authHeader = req.headers["authorization"]
//   const token = authHeader && authHeader.split(" ")[1]

//   if (!token) {
//     return res.status(401).json({ error: "Access token required" })
//   }

//   jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
//     if (err) {
//       return res.status(403).json({ error: "Invalid or expired token" })
//     }
//     req.user = user
//     next()
//   })
// }

// Root endpoint
app.get("/", (req, res) => {
  res.json({
    message: "Bloomberg-style Stock Terminal API with ClickHouse",
    version: "2.0.0",
    database: "ClickHouse",
    endpoints: {
      health: "/health",
      docs: "/api-docs",
      auth: "/api/auth",
      market: "/api/market",
      analytics: "/api/analytics",
      portfolio: "/api/portfolio",
      research: "/api/research",
      trading: "/api/trading",
      screening: "/api/screening",
      backtesting: "/api/backtesting",
      economic: "/api/economic",
    },
  })
})

// Health check endpoint
app.get("/health", async (req, res) => {
  try {
    // Check ClickHouse connection
    await clickhouse.query({ query: "SELECT 1" })

    // Check Redis connection (optional)
    let redisStatus = "disconnected"
    try {
      if (redis && redis.isOpen) {
        await redis.ping()
        redisStatus = "connected"
      }
    } catch (redisError) {
      logger.warn("Redis health check failed:", redisError.message)
    }

    res.json({
      status: "healthy",
      timestamp: new Date().toISOString(),
      services: {
        clickhouse: "connected",
        redis: redisStatus,
      },
    })
  } catch (error) {
    logger.error("Health check failed:", error)
    res.status(503).json({
      status: "unhealthy",
      timestamp: new Date().toISOString(),
      error: error.message,
    })
  }
})

// Mount route modules
app.use("/api/market", marketRoutes)
app.use("/api/analytics", analyticsRoutes)
app.use("/api/research", researchRoutes)
app.use("/api/portfolio", portfolioRoutes)
app.use("/api/screening", screeningRoutes)
app.use("/api/backtesting", backtestingRoutes)
app.use("/api/trading", tradingRoutes)
app.use("/api/economic", economicRoutes)

// Authentication endpoints
app.post("/api/auth/register", async (req, res) => {
  try {
    const schema = Joi.object({
      username: Joi.string().alphanum().min(3).max(30).required(),
      email: Joi.string().email().required(),
      password: Joi.string().min(6).required(),
      firstName: Joi.string().optional(),
      lastName: Joi.string().optional(),
    })

    const { error, value } = schema.validate(req.body)
    if (error) {
      return res.status(400).json({ error: error.details[0].message })
    }

    const { username, email, password, firstName, lastName } = value

    // Check if user exists
    const existingUser = await clickhouse.query({
      query: "SELECT id FROM users WHERE username = {username:String} OR email = {email:String}",
      query_params: { username, email },
    })

    const userData = await existingUser.json()
    if (userData.data.length > 0) {
      return res.status(409).json({ error: "Username or email already exists" })
    }

    // Hash password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 10
    const passwordHash = await bcrypt.hash(password, saltRounds)

    // Insert user
    const userId = Date.now() // Simple ID generation
    await clickhouse.insert({
      table: "users",
      values: [
        {
          id: userId,
          username,
          email,
          password_hash: passwordHash,
          first_name: firstName || "",
          last_name: lastName || "",
          is_active: 1,
          is_verified: 0,
        },
      ],
    })

    res.status(201).json({
      message: "User registered successfully",
      userId,
    })
  } catch (error) {
    logger.error("Registration error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

app.post("/api/auth/login", async (req, res) => {
  try {
    const schema = Joi.object({
      username: Joi.string().required(),
      password: Joi.string().required(),
    })

    const { error, value } = schema.validate(req.body)
    if (error) {
      return res.status(400).json({ error: error.details[0].message })
    }

    const { username, password } = value

    // Get user
    const result = await clickhouse.query({
      query:
        "SELECT id, username, email, password_hash, is_active FROM users WHERE username = {username:String} OR email = {username:String}",
      query_params: { username },
    })

    const users = await result.json()
    if (users.data.length === 0) {
      return res.status(401).json({ error: "Invalid credentials" })
    }

    const user = users.data[0]
    if (!user.is_active) {
      return res.status(401).json({ error: "Account is disabled" })
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash)
    if (!isValidPassword) {
      return res.status(401).json({ error: "Invalid credentials" })
    }

    // Generate JWT token
    const token = jwt.sign(
      {
        userId: user.id,
        username: user.username,
        email: user.email,
      },
      process.env.JWT_SECRET,
      { expiresIn: "24h" }
    )

    res.json({
      message: "Login successful",
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
      },
    })
  } catch (error) {
    logger.error("Login error:", error)
    res.status(500).json({ error: "Internal server error" })
  }
})

// WebSocket handling
wss.on("connection", (ws) => {
  logger.info("New WebSocket connection established")

  ws.on("message", (message) => {
    try {
      const data = JSON.parse(message)

      switch (data.type) {
        case "subscribe":
          // Handle subscription to real-time data
          ws.symbol = data.symbol
          ws.send(
            JSON.stringify({
              type: "subscribed",
              symbol: data.symbol,
              message: `Subscribed to ${data.symbol}`,
            })
          )
          break

        case "unsubscribe":
          // Handle unsubscription
          ws.symbol = null
          ws.send(
            JSON.stringify({
              type: "unsubscribed",
              message: "Unsubscribed from all symbols",
            })
          )
          break
      }
    } catch (error) {
      logger.error("WebSocket message error:", error)
    }
  })

  ws.on("close", () => {
    logger.info("WebSocket connection closed")
  })
})

// Error handling middleware
app.use((error, req, res) => {
  logger.error("Unhandled error:", error)
  res.status(500).json({ error: "Internal server error" })
})

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" })
})

// Initialize services
async function initialize() {
  try {
    // Connect to Redis (optional)
    if (redis) {
      try {
        await redis.connect()
        logger.info("Connected to Redis")
      } catch (redisError) {
        logger.warn("Failed to connect to Redis (continuing without cache):", redisError.message)
      }
    }

    // Test ClickHouse connection
    await clickhouse.query({ query: "SELECT 1" })
    logger.info("Connected to ClickHouse")

    // Start server
    const port = process.env.API_PORT || 3000
    server.listen(port, () => {
      logger.info(`Bloomberg-style API Gateway listening on port ${port}`)
      logger.info(`API Documentation available at http://localhost:${port}/api-docs`)
      logger.info(`WebSocket server running on ws://localhost:${port}`)
    })
  } catch (error) {
    logger.error("Failed to initialize service:", error)
    process.exit(1)
  }
}

// Graceful shutdown
process.on("SIGTERM", async () => {
  logger.info("Received SIGTERM, shutting down gracefully")
  if (redis && redis.isOpen) {
    await redis.disconnect()
  }
  await clickhouse.close()
  server.close()
  process.exit(0)
})

// Start the service
initialize()
