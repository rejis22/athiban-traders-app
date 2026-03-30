const express = require('express');
const router = express.Router();
const { getDashboardMetrics } = require('../controllers/dashboardController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').get(protect, getDashboardMetrics);

module.exports = router;
