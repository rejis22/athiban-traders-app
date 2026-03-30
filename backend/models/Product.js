const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema({
    code: {
        type: String,
        required: [true, 'Please add a product code'],
        unique: true,
        trim: true
    },
    name: {
        type: String,
        required: [true, 'Please add a product name'],
        trim: true
    },
    hsnCode: {
        type: String,
        default: ''
    },
    taxRate: {
        type: Number,
        default: 18.0
    },
    category: {
        type: String,
        default: 'General'
    },
    price: {
        type: Number,
        required: [true, 'Please add a price']
    },
    stock: {
        type: Number,
        required: [true, 'Please add stock quantity'],
        min: [0, 'Stock cannot be negative']
    },
    unit: {
        type: String,
        required: [true, 'Please specify a unit (e.g., nos, kg)'],
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Product', ProductSchema);
