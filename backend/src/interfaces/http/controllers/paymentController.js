import { asyncHandler } from '../middleware/asyncHandler.js';

export function paymentController(paymentService) {
  return {
    config: asyncHandler(async (_req, res) => {
      res.json({ data: paymentService.config() });
    }),
    createOrder: asyncHandler(async (req, res) => {
      res.status(201).json({
        data: await paymentService.createOrder({
          amountPaise: req.body?.amountPaise,
          receipt: req.body?.receipt,
        }),
      });
    }),
  };
}
