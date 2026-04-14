require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./models/User');

const fixUser = async () => {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        
        await User.deleteOne({ email: 'athibantraders2005@gmail.com' }).catch(() => {});
        
        await User.create({
            name: 'Athiban Admin 2',
            email: 'athibantraders2005@gmail.com',
            password: '7678',
            role: 'admin'
        });

        console.log('Created valid-spelling user successfully');
        process.exit();
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

fixUser();
