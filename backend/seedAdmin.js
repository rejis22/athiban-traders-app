const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/User');

dotenv.config();

const seedAdmin = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('MongoDB Connected');
    
    // Check if admin exists
    const adminExists = await User.findOne({ email: 'athibantredars2005@gmail.com' });
    if (adminExists) {
      console.log('Admin user already exists!');
      process.exit(0);
    }
    
    // Create admin user
    const admin = await User.create({
      name: 'Athiban Admin',
      email: 'athibantredars2005@gmail.com',
      password: '7678', // This will be hashed automatically if User schema has pre-save hook
      role: 'admin'
    });
    
    console.log('Admin user created successfully:');
    console.log('Email: athibantredars2005@gmail.com');
    // Note: It's 7678 as requested by previous logs
    process.exit(0);
  } catch (error) {
    console.error('Error seeding admin user:\n', error);
    process.exit(1);
  }
};

seedAdmin();
