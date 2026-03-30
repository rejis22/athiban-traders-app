const express = require('express');
const router = express.Router();
const {
    createBill,
    getBillById,
    getBills,
} = require('../controllers/billController');
const { protect } = require('../middleware/authMiddleware');

router.route('/').post(protect, createBill).get(protect, getBills);
router.route('/:id').get(protect, getBillById);

module.exports = router;
