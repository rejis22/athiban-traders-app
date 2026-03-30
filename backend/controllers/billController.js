const Bill = require('../models/Bill');

// @desc    Create new bill
// @route   POST /api/bills
// @access  Private
const createBill = async (req, res) => {
    try {
        const {
            billNumber,
            date,
            customer,
            customerName,
            customerPhone,
            customerAddress,
            items,
            subTotal,
            taxRate,
            taxAmount,
            discount,
            roundOff,
            grandTotal,
        } = req.body;

        if (items && items.length === 0) {
            res.status(400).json({ message: 'No bill items' });
            return;
        }

        const bill = new Bill({
            billNumber,
            date,
            customer,
            customerName: customerName || 'Walk-in Customer',
            customerPhone,
            customerAddress,
            items,
            subTotal,
            taxRate,
            taxAmount,
            discount,
            roundOff,
            grandTotal,
        });

        const createdBill = await bill.save();

        // Reduce stock for products
        if (items && items.length > 0) {
            for (const item of items) {
                if (item.product) {
                    await require('../models/Product').findByIdAndUpdate(
                        item.product,
                        { $inc: { stock: -Math.abs(item.quantity) } }
                    );
                }
            }
        }

        res.status(201).json(createdBill);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get bill by ID
// @route   GET /api/bills/:id
// @access  Private
const getBillById = async (req, res) => {
    try {
        const bill = await Bill.findById(req.params.id).populate('customer', 'name phone address');

        if (bill) {
            res.json(bill);
        } else {
            res.status(404).json({ message: 'Bill not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all bills or filter by date range
// @route   GET /api/bills
// @access  Private
const getBills = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;
        let query = {};

        if (startDate && endDate) {
            query.date = {
                $gte: new Date(startDate),
                $lte: new Date(endDate),
            };
        }

        const bills = await Bill.find(query)
            .populate('customer', 'name')
            .sort({ date: -1 });
            
        res.json(bills);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    createBill,
    getBillById,
    getBills,
};
