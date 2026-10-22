import { asyncHandler } from '../middleware/asyncHandler.js';

export function noticeController(noticeService) {
  return {
    list: asyncHandler(async (req, res) => {
      res.json({ data: noticeService.list(req.device) });
    }),
    markAllRead: asyncHandler(async (req, res) => {
      res.json({ data: noticeService.markAllRead(req.device) });
    }),
  };
}
