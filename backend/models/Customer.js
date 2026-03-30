const mongoose = require('mongoose');

const CustomerSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please add a customer name'],
        trim: true
    },
    phone: {
        type: String,
        required: [true, 'Please add a phone number'],
        match: [
            /^[0-9]{10}$/,
            'Please add a valid 10-digit phone number'
        ]
    },
    address: {
        type: String,
        required: [true, 'Please add an address']
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Customer', CustomerSchema);
