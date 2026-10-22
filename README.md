# Shoe Factory

This repository is a small monorepo with two apps:

- **Shop** — the Flutter app in this folder
- **Admin** — the web console in `apps/admin`

Ecommerce app for the Shoe Factory shoe shop. The interface uses the brand logo and the green, black and white theme.

Shopping, the cart, checkout and orders use the shop API. Payment through Razorpay is confirmed by the API before an order is stored. Coupons, branches and notices edited in admin are the ones the app reads.

## What you can do

- Browse home, categories, search, sort, deals and new arrivals
- Open a pair, pick colour, UK size and quantity, then add it or buy it now
- Save pairs to a wishlist
- Apply TREND10, FACTORY200 or FREESHIP in the cart
- Check out for home delivery or free store pickup
- Sign in with a mobile number and a 6-digit code, save addresses and edit your profile
- Track, cancel or order again from My orders
- Switch the shopping branch, read notifications, help and policies

## Architecture

MVVM with a clean split between layers:

- `domain` holds entities, repository contracts, pricing and use cases
- `data` holds the demo catalog and in-memory repositories. The API stores the shop in SQLite (`backend/data/shop.db`).
- `presentation` holds view models and screens
- `app` wires the layers together

View models are `ChangeNotifier`s. Screens listen to them and never talk to the data sources directly.

## Admin web

The admin covers products, orders, customers, branches, coupons and notices. Products shows every pair with its price, units on hand, units sold, and a status of in stock, low stock, out of stock or hidden. An admin can add a product from that page.

```bash
npm install
npm run admin
```

Open http://localhost:5173 and sign in with mobile `9876501234`. The 6-digit code is shown on the sign-in card. Profile lets the signed-in admin change their name, email, and the mobile number used next time they sign in. The shop demo number is `9876543210`, and email sign-in remains `shopper@shoefactory.shop` / `trend`.

Products, orders, customers, branches, coupons, notices and the admin profile are stored in the shop API (`backend/data/shop.db`). The app reads the same catalogue, branches, coupons and notices.

## Run the shop locally

1. Install Flutter stable.
2. From this folder run:

```bash
flutter pub get
flutter run
```

Product photos are loaded from Unsplash and need a network connection. The Android app is labeled Shoe Factory and requests internet access so those photos can load.
