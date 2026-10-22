import { quote } from '../lib/pricing'
import type {
  AdminData,
  Branch,
  Coupon,
  Customer,
  Notice,
  Order,
  OrderLine,
  Product,
} from '../types'

const photo = (id: string) =>
  `https://images.unsplash.com/${id}?auto=format&fit=crop&w=900&q=80`

function shoe(
  input: Omit<Product, 'imageUrl' | 'images' | 'listed' | 'colors' | 'sizes' | 'isNew'> & {
    image: string
    colors?: string[]
    sizes?: number[]
    isNew?: boolean
    listed?: boolean
    stock: number
  },
): Product {
  const imageUrl = photo(input.image)
  return {
    id: input.id,
    name: input.name,
    category: input.category,
    price: input.price,
    oldPrice: input.oldPrice,
    rating: input.rating,
    reviewCount: input.reviewCount,
    description: input.description,
    stock: input.stock,
    badge: input.badge,
    imageUrl,
    images: [{ url: imageUrl, position: 'Front' }],
    colors: input.colors ?? ['Black', 'White'],
    sizes: input.sizes ?? [6, 7, 8, 9, 10, 11],
    isNew: input.isNew ?? false,
    listed: input.listed ?? true,
  }
}

const catalog: Product[] = [
  shoe({
    id: 'sf001',
    name: 'Air Motion Runner',
    category: 'Sneakers',
    price: 6499,
    oldPrice: 7999,
    rating: 4.6,
    reviewCount: 128,
    image: 'photo-1542291026-7eec264c27ff',
    description:
      'Lightweight everyday sneakers with cushioned support, a breathable upper and a bold streetwear look.',
    badge: 'BESTSELLER',
    colors: ['Red', 'Black', 'White'],
    stock: 8,
  }),
  shoe({
    id: 'sf002',
    name: 'Cloud Knit Sneaker',
    category: 'Sneakers',
    price: 5299,
    oldPrice: 6499,
    rating: 4.5,
    reviewCount: 67,
    image: 'photo-1600185365483-26d7a4cc7519',
    description: 'A soft knit sneaker with a clean profile for workdays and weekends.',
    colors: ['White', 'Grey', 'Green'],
    stock: 10,
  }),
  shoe({
    id: 'sf003',
    name: 'Urban Flex Trainer',
    category: 'Sports',
    price: 8999,
    oldPrice: 11999,
    rating: 4.8,
    reviewCount: 96,
    image: 'photo-1460353581641-37baddab0fa2',
    description: 'A versatile trainer for movement, gym sessions and all-day wear.',
    badge: '25% OFF',
    colors: ['Black', 'Green', 'Grey'],
    stock: 6,
  }),
  shoe({
    id: 'sf004',
    name: 'Trail Pro Outdoor',
    category: 'Sports',
    price: 7499,
    oldPrice: 8999,
    rating: 4.5,
    reviewCount: 61,
    image: 'photo-1552346154-21d32810aba3',
    description: 'Durable grip and dependable comfort for weekend trails.',
    badge: 'NEW',
    colors: ['Brown', 'Black', 'Green'],
    stock: 9,
    isNew: true,
  }),
  shoe({
    id: 'sf005',
    name: 'Night Runner Pro',
    category: 'Sports',
    price: 9999,
    oldPrice: 12999,
    rating: 4.9,
    reviewCount: 84,
    image: 'photo-1491553895911-0055eca6402d',
    description: 'Our most cushioned runner, for daily miles and race day.',
    badge: 'BESTSELLER',
    colors: ['Black', 'Grey'],
    stock: 3,
  }),
  shoe({
    id: 'sf006',
    name: 'Classic Court Low',
    category: 'Casual',
    price: 4499,
    oldPrice: 5499,
    rating: 4.4,
    reviewCount: 74,
    image: 'photo-1549298916-b41d501d3772',
    description: 'A timeless low-top that pairs with an everyday wardrobe.',
    colors: ['White', 'Navy', 'Black'],
    stock: 14,
  }),
  shoe({
    id: 'sf007',
    name: 'Everyday Slip-On',
    category: 'Casual',
    price: 2999,
    oldPrice: 3499,
    rating: 4.3,
    reviewCount: 48,
    image: 'photo-1560769629-975ec94e6a86',
    description: 'A relaxed slip-on for errands and travel days.',
    colors: ['Black', 'White'],
    stock: 20,
  }),
  shoe({
    id: 'sf008',
    name: 'Weekend Boot',
    category: 'Casual',
    price: 3999,
    oldPrice: 4999,
    rating: 4.2,
    reviewCount: 58,
    image: 'photo-1514989940723-e8e51635b782',
    description: 'A rugged boot with a soft lining for cooler days.',
    colors: ['Brown', 'Black'],
    sizes: [6, 7, 8, 9, 10],
    stock: 0,
  }),
  shoe({
    id: 'sf009',
    name: 'Executive Formal',
    category: 'Formal',
    price: 5999,
    oldPrice: 6999,
    rating: 4.7,
    reviewCount: 53,
    image: 'photo-1533867617858-e7b97e060509',
    description: 'A polished formal shoe for work and special occasions.',
    colors: ['Brown', 'Black'],
    stock: 7,
  }),
  shoe({
    id: 'sf010',
    name: 'Heritage Loafer',
    category: 'Formal',
    price: 6799,
    oldPrice: 7999,
    rating: 4.6,
    reviewCount: 41,
    image: 'photo-1614252369475-5312f9b6c2f5',
    description: 'A leather loafer that works from meetings to dinner.',
    colors: ['Brown', 'Black'],
    stock: 6,
  }),
  shoe({
    id: 'sf011',
    name: 'Coastline Sandal',
    category: 'Sandals',
    price: 1999,
    oldPrice: 2499,
    rating: 4.4,
    reviewCount: 39,
    image: 'photo-1603487742131-4160ec999306',
    description: 'A warm-weather sandal with a cushioned footbed.',
    badge: 'NEW',
    colors: ['Beige', 'Brown', 'Black'],
    sizes: [6, 7, 8, 9, 10],
    stock: 11,
    isNew: true,
  }),
  shoe({
    id: 'sf012',
    name: 'Monsoon Slide',
    category: 'Sandals',
    price: 1499,
    oldPrice: 1899,
    rating: 4.1,
    reviewCount: 33,
    image: 'photo-1562273138-f46be4ebdf33',
    description: 'A quick-dry slide for rain and home.',
    badge: 'TRENDING',
    colors: ['Green', 'Black', 'Beige'],
    sizes: [6, 7, 8, 9, 10],
    stock: 4,
    isNew: true,
  }),
]

const branches: Branch[] = [
  {
    id: 'tvm',
    name: 'Trivandrum Central',
    address: 'MG Road, Thiruvananthapuram',
    hours: 'Open today · 10:00 AM–9:00 PM',
    phone: '0471 555 0101',
  },
  {
    id: 'kochi',
    name: 'Kochi Marine Drive',
    address: 'Marine Drive, Kochi',
    hours: 'Open today · 10:00 AM–9:30 PM',
    phone: '0484 555 0118',
  },
  {
    id: 'clt',
    name: 'Calicut Main',
    address: 'Mavoor Road, Kozhikode',
    hours: 'Open today · 10:00 AM–9:00 PM',
    phone: '0495 555 0134',
  },
]

const coupons: Coupon[] = [
  { code: 'TREND10', label: '10% off', kind: 'percent', value: 10, minSubtotal: 0, active: true },
  {
    code: 'FACTORY200',
    label: '₹200 off above ₹1,999',
    kind: 'flat',
    value: 200,
    minSubtotal: 1999,
    active: true,
  },
  {
    code: 'FREESHIP',
    label: 'Free delivery above ₹999',
    kind: 'shipping',
    value: 0,
    minSubtotal: 999,
    active: true,
  },
]

const notices: Notice[] = [
  {
    id: 'n1',
    title: 'Your order is being prepared',
    body: 'SF-10241 is being packed at Trivandrum Central.',
    timeLabel: 'Today',
  },
  {
    id: 'n2',
    title: 'TREND10 is live this week',
    body: 'Take 10% off your cart with code TREND10.',
    timeLabel: 'Yesterday',
  },
  {
    id: 'n3',
    title: 'New sandals just landed',
    body: 'Coastline Sandal and Monsoon Slide are in store and online.',
    timeLabel: 'This week',
  },
]

function daysAgo(days: number, hour: number) {
  const date = new Date()
  date.setDate(date.getDate() - days)
  date.setHours(hour, 20, 0, 0)
  return date.toISOString()
}

function onDayInMonth(monthsBack: number, day: number, hour: number) {
  const date = new Date()
  date.setDate(1)
  date.setHours(hour, 15, 0, 0)
  date.setMonth(date.getMonth() - monthsBack)
  const last = new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate()
  date.setDate(Math.min(day, last))
  return date
}

const shoppers = [
  {
    customerId: 'c1',
    contactName: 'Shoe Factory Shopper',
    contactPhone: '9876543210',
    destination: '12, MG Road, Thiruvananthapuram 695001',
    branchId: 'tvm',
  },
  {
    customerId: 'c2',
    contactName: 'Anjali Menon',
    contactPhone: '9847011122',
    destination: '9, Panampilly Nagar, Kochi 682036',
    branchId: 'kochi',
  },
  {
    customerId: 'c3',
    contactName: 'Rahul Nair',
    contactPhone: '9895123456',
    destination: '18, Mavoor Road, Kozhikode 673001',
    branchId: 'clt',
  },
]

const historyPlan: { ago: number; day: number; shopper: number; lines: [string, number][]; pickup?: boolean }[] = [
  { ago: 11, day: 6, shopper: 0, lines: [['sf004', 1], ['sf008', 1]] },
  { ago: 11, day: 18, shopper: 1, lines: [['sf006', 2]], pickup: true },
  { ago: 10, day: 4, shopper: 2, lines: [['sf001', 2]] },
  { ago: 10, day: 19, shopper: 0, lines: [['sf009', 1], ['sf002', 1]] },
  { ago: 9, day: 8, shopper: 1, lines: [['sf003', 1], ['sf005', 1]] },
  { ago: 9, day: 21, shopper: 2, lines: [['sf005', 1]], pickup: true },
  { ago: 8, day: 5, shopper: 0, lines: [['sf004', 1], ['sf003', 1]] },
  { ago: 8, day: 17, shopper: 1, lines: [['sf009', 1], ['sf008', 1]], pickup: true },
  { ago: 7, day: 9, shopper: 2, lines: [['sf001', 2], ['sf005', 1]] },
  { ago: 7, day: 23, shopper: 0, lines: [['sf004', 1]] },
  { ago: 6, day: 4, shopper: 1, lines: [['sf003', 2]] },
  { ago: 6, day: 18, shopper: 2, lines: [['sf005', 1], ['sf009', 1]], pickup: true },
  { ago: 5, day: 7, shopper: 0, lines: [['sf005', 1], ['sf004', 1]] },
  { ago: 5, day: 20, shopper: 1, lines: [['sf010', 1], ['sf006', 1]] },
  { ago: 4, day: 6, shopper: 2, lines: [['sf001', 2]], pickup: true },
  { ago: 4, day: 16, shopper: 0, lines: [['sf005', 1], ['sf003', 1]] },
  { ago: 3, day: 8, shopper: 1, lines: [['sf005', 2]] },
  { ago: 3, day: 22, shopper: 2, lines: [['sf003', 1], ['sf004', 1]], pickup: true },
  { ago: 2, day: 5, shopper: 0, lines: [['sf001', 2], ['sf005', 1]] },
  { ago: 2, day: 19, shopper: 1, lines: [['sf001', 1], ['sf003', 1]] },
  { ago: 1, day: 6, shopper: 2, lines: [['sf005', 1], ['sf003', 1]] },
  { ago: 1, day: 14, shopper: 0, lines: [['sf004', 1], ['sf010', 1], ['sf002', 1]], pickup: true },
]

function historyOrders(byId: (id: string) => Product): Order[] {
  return historyPlan.map((plan, index) => {
    const placed = onDayInMonth(plan.ago, plan.day, 10 + (index % 6))
    const month = String(placed.getMonth() + 1).padStart(2, '0')
    const shopper = shoppers[plan.shopper]
    return makeOrder({
      id: `SF-H${placed.getFullYear()}${month}-${index % 2 === 0 ? 1 : 2}`,
      placedAt: placed.toISOString(),
      lines: plan.lines.map(([id, quantity]) => {
        const product = byId(id)
        return line(product, 8, product.colors[0] ?? 'Black', quantity)
      }),
      fulfilment: plan.pickup ? 'pickup' : 'delivery',
      paymentMethod: index % 3 === 0 ? 'upi' : index % 3 === 1 ? 'card' : 'cod',
      status: 'completed',
      destination: shopper.destination,
      contactName: shopper.contactName,
      contactPhone: shopper.contactPhone,
      customerId: shopper.customerId,
      branchId: shopper.branchId,
    })
  })
}

function line(product: Product, size: number, color: string, quantity = 1): OrderLine {
  return {
    productId: product.id,
    name: product.name,
    imageUrl: product.imageUrl,
    unitPrice: product.price,
    color,
    size,
    quantity,
  }
}

function makeOrder(
  input: Omit<Order, 'subtotal' | 'discount' | 'deliveryFee' | 'total' | 'couponCode'> & {
    couponCode?: string
  },
): Order {
  const subtotal = input.lines.reduce((sum, item) => sum + item.unitPrice * item.quantity, 0)
  const priced = quote(subtotal, input.couponCode, input.fulfilment === 'pickup')
  return {
    ...input,
    subtotal: priced.subtotal,
    discount: priced.discount,
    deliveryFee: priced.deliveryFee,
    total: priced.total,
    couponCode: priced.couponCode,
  }
}

export function createSeed(): AdminData {
  const products = catalog.map((product) => ({
    ...product,
    colors: [...product.colors],
    sizes: [...product.sizes],
  }))
  const byId = (id: string) => {
    const product = products.find((item) => item.id === id)
    if (!product) throw new Error(`Missing product ${id}`)
    return product
  }

  const customers: Customer[] = [
    {
      id: 'c1',
      name: 'Shoe Factory Shopper',
      email: 'shopper@shoefactory.shop',
      phone: '9876543210',
      city: 'Thiruvananthapuram',
      joinedAt: daysAgo(400, 11),
    },
    {
      id: 'c2',
      name: 'Anjali Menon',
      email: 'anjali@example.com',
      phone: '9847011122',
      city: 'Kochi',
      joinedAt: daysAgo(380, 15),
    },
    {
      id: 'c3',
      name: 'Rahul Nair',
      email: 'rahul@example.com',
      phone: '9895123456',
      city: 'Kozhikode',
      joinedAt: daysAgo(340, 9),
    },
    {
      id: 'c4',
      name: 'Meera Joseph',
      email: 'meera@example.com',
      phone: '9745123987',
      city: 'Thiruvananthapuram',
      joinedAt: daysAgo(22, 18),
    },
    {
      id: 'c5',
      name: 'Dev Krishnan',
      email: 'dev@example.com',
      phone: '9037456123',
      city: 'Thiruvananthapuram',
      joinedAt: daysAgo(6, 13),
    },
  ]

  const orders: Order[] = [
    ...historyOrders(byId),
    makeOrder({
      id: 'SF-10241',
      placedAt: daysAgo(2, 14),
      lines: [line(byId('sf001'), 8, 'Red'), line(byId('sf006'), 8, 'White')],
      fulfilment: 'delivery',
      paymentMethod: 'upi',
      status: 'preparing',
      destination: '12, MG Road, Thiruvananthapuram 695001',
      contactName: 'Shoe Factory Shopper',
      contactPhone: '9876543210',
      customerId: 'c1',
      branchId: 'tvm',
    }),
    makeOrder({
      id: 'SF-10260',
      placedAt: daysAgo(0, 9),
      lines: [line(byId('sf011'), 8, 'Beige'), line(byId('sf012'), 8, 'Green')],
      fulfilment: 'delivery',
      paymentMethod: 'upi',
      status: 'confirmed',
      destination: '44, Vellayambalam, Thiruvananthapuram 695010',
      contactName: 'Dev Krishnan',
      contactPhone: '9037456123',
      customerId: 'c5',
      branchId: 'tvm',
      couponCode: 'FREESHIP',
    }),
    makeOrder({
      id: 'SF-10255',
      placedAt: daysAgo(0, 11),
      lines: [line(byId('sf004'), 9, 'Brown')],
      fulfilment: 'pickup',
      paymentMethod: 'upi',
      status: 'confirmed',
      destination: 'Kochi Marine Drive',
      contactName: 'Anjali Menon',
      contactPhone: '9847011122',
      customerId: 'c2',
      branchId: 'kochi',
    }),
    makeOrder({
      id: 'SF-10218',
      placedAt: daysAgo(1, 16),
      lines: [line(byId('sf005'), 10, 'Black')],
      fulfilment: 'delivery',
      paymentMethod: 'card',
      status: 'onTheWay',
      destination: '18, Mavoor Road, Kozhikode 673001',
      contactName: 'Rahul Nair',
      contactPhone: '9895123456',
      customerId: 'c3',
      branchId: 'clt',
      couponCode: 'TREND10',
    }),
    makeOrder({
      id: 'SF-10190',
      placedAt: daysAgo(9, 12),
      lines: [line(byId('sf009'), 8, 'Brown'), line(byId('sf010'), 8, 'Black')],
      fulfilment: 'delivery',
      paymentMethod: 'upi',
      status: 'completed',
      destination: '7, Kowdiar, Thiruvananthapuram 695003',
      contactName: 'Meera Joseph',
      contactPhone: '9745123987',
      customerId: 'c4',
      branchId: 'tvm',
      couponCode: 'FACTORY200',
    }),
    makeOrder({
      id: 'SF-10182',
      placedAt: daysAgo(18, 15),
      lines: [line(byId('sf006'), 8, 'White')],
      fulfilment: 'delivery',
      paymentMethod: 'cod',
      status: 'completed',
      destination: '12, MG Road, Thiruvananthapuram 695001',
      contactName: 'Shoe Factory Shopper',
      contactPhone: '9876543210',
      customerId: 'c1',
      branchId: 'tvm',
    }),
    makeOrder({
      id: 'SF-10140',
      placedAt: daysAgo(12, 17),
      lines: [line(byId('sf002'), 7, 'White')],
      fulfilment: 'delivery',
      paymentMethod: 'cod',
      status: 'cancelled',
      destination: '9, Panampilly Nagar, Kochi 682036',
      contactName: 'Anjali Menon',
      contactPhone: '9847011122',
      customerId: 'c2',
      branchId: 'kochi',
    }),
    makeOrder({
      id: 'SF-10110',
      placedAt: daysAgo(30, 13),
      lines: [line(byId('sf008'), 9, 'Brown')],
      fulfilment: 'pickup',
      paymentMethod: 'cod',
      status: 'completed',
      destination: 'Calicut Main',
      contactName: 'Rahul Nair',
      contactPhone: '9895123456',
      customerId: 'c3',
      branchId: 'clt',
    }),
  ]

  return {
    products,
    orders,
    customers,
    branches: branches.map((branch) => ({ ...branch })),
    coupons: coupons.map((coupon) => ({ ...coupon })),
    notices: notices.map((notice) => ({ ...notice })),
    revenueBackfill: true,
  }
}
