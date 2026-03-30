const Bill = require('../models/Bill');

// @desc    Get dashboard metrics (total sales, bills count, etc.)
// @route   GET /api/dashboard
// @access  Private
const getDashboardMetrics = async (req, res) => {
    try {
        const { period } = req.query; // 'daily', 'weekly', 'monthly'
        
        const now = new Date();
        let startDate;

        if (period === 'daily') {
            startDate = new Date(now.setHours(0, 0, 0, 0));
        } else if (period === 'weekly') {
            const firstDay = now.getDate() - now.getDay();
            startDate = new Date(now.setDate(firstDay));
            startDate.setHours(0, 0, 0, 0);
        } else if (period === 'monthly') {
            startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        } else {
            // Default to all time or specific logic
            startDate = new Date(0); // Epoch
        }

        const matchStage = {
            date: { $gte: startDate }
        };

        const metrics = await Bill.aggregate([
            { $match: matchStage },
            {
                $group: {
                    _id: null,
                    totalSales: { $sum: "$grandTotal" },
                    totalBills: { $sum: 1 },
                }
            }
        ]);

        res.json({
            period: period || 'all',
            metrics: metrics.length > 0 ? metrics[0] : { totalSales: 0, totalBills: 0 }
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getDashboardMetrics,
};
