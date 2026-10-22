# Shoe Factory

This repository is a small monorepo with two apps:

- **Shop** — the Flutter app in this folder
- **Admin** — the web console in `apps/admin`

Ecommerce app for the Shoe Factory shoe shop. The interface uses the brand logo and the green, black and white theme.

Shopping, the cart, checkout and orders run on this device with demo catalog data. Payment is simulated: no card or UPI charge is made.

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
- `data` holds the demo catalog and in-memory repositories
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

Changes stay in this browser. The shop app keeps its own in-memory copy until both apps share a backend.

## Run the shop locally

1. Install Flutter stable.
2. From this folder run:

```bash
flutter pub get
flutter run
```

Product photos are loaded from Unsplash and need a network connection. The Android app is labeled Shoe Factory and requests internet access so those photos can load.
