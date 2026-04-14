const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const morgan = require('morgan');

// Load env vars
dotenv.config();

// Route files
const authRoutes = require('./routes/authRoutes');
const productRoutes = require('./routes/productRoutes');
const customerRoutes = require('./routes/customerRoutes');
const billRoutes = require('./routes/billRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');

const app = express();

// Middleware
app.use(express.json());
app.use(cors());
app.use(morgan('dev'));

// Mount routers
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/bills', billRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Base route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to Athiban Traders API' });
});

// Create an instance of the backend server
const PORT = process.env.PORT || 5000;

const startServer = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            console.error('CRITICAL: MONGODB_URI is undefined. Check .env file.');
        }

        // We will mock the mongoose connection so the dev can run this locally without crashing if Atlas is not perfectly setup yet, but we'll try to connect normally
        await mongoose.connect(process.env.MONGODB_URI, {
            serverSelectionTimeoutMS: 5000,
        });
        console.log('MongoDB Connected successfully');
        
        app.listen(PORT, () => {
            console.log(`Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
        });
    } catch (error) {
        console.error('Error connecting to MongoDB:', error.message);
        console.log('Server is running but database is disconnected. Please check your MongoDB Atlas URI in .env');
        
        // Still start app to allow testing basic routes
        app.listen(PORT, () => {
             console.log(`Server running on port ${PORT} (Database Disconnected Mode)`);
        });
    }
};

startServer();
