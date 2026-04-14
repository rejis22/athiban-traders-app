require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const fixUser = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to DB');

        // Delete existing unhashed user
        await User.deleteOne({ email: 'athibantredars2005@gmail.com' });
        console.log('Deleted old user');

        // Create new user (this triggers the new bcrypt pre-save hook)
        const user = await User.create({
            name: 'Athiban Admin',
            email: 'athibantredars2005@gmail.com',
            password: '7678',
            role: 'admin'
        });

        console.log('Created new user with hashed password');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

fixUser();
