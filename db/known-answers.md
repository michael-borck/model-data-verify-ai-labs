# Known answers for the Harbour Coffee case

All money is in cents unless stated otherwise. "Shipped revenue" means the sum of
`quantity * unit_price_cents` for orders with `status = 'shipped'`.

## Headline answers

| Question | Answer |
|---|---|
| Shipped revenue, all time | 53,600 cents ($536.00) |
| Shipped revenue, April 2026 | 14,800 cents ($148.00) |
| Unpaid invoices as of 30 April 2026 | 2 invoices, 15,800 cents ($158.00) |
| Product with the most shipped units | Harbour Espresso Blend 1kg (6 units) |
| Customer with the highest shipped revenue | Ada Lovelace (17,800 cents) |
| Average shipped order value | 7,657.14 cents, rounded to 7,657 |
| Customers with no orders | Barbara Liskov |
| Products with no shipped sales | Monthly Subscription |

## Shipped revenue by month

| Month | Orders | Revenue | Average order |
|---|---:|---:|---:|
| 2026-01 | 2 | 16,700 | 8,350 |
| 2026-02 | 1 | 6,800 | 6,800 |
| 2026-03 | 2 | 15,300 | 7,650 |
| 2026-04 | 2 | 14,800 | 7,400 |

## Product units shipped

| Product | Units | Revenue |
|---|---:|---:|
| Harbour Espresso Blend 1kg | 6 | 19,200 |
| Harbour Filter Blend 1kg | 2 | 6,000 |
| Harbour Decaf 1kg | 3 | 10,200 |
| Harbour Ceramic Mug | 4 | 7,200 |
| Harbour Gift Box | 2 | 11,000 |
| Monthly Subscription | 0 | 0 |

## Customer shipped revenue

| Customer | Revenue |
|---|---:|
| Ada Lovelace | 17,800 |
| Grace Hopper | 14,700 |
| Edsger Dijkstra | 9,100 |
| Alan Turing | 6,800 |
| Katherine Johnson | 5,200 |
| Barbara Liskov | 0 |

## Invoice status as of 30 April 2026

| Invoice | Order | Due | Paid | Total |
|---|---:|---|---|---:|
| 1 | 1 | 2026-01-19 | 2026-01-10 | 8,200 |
| 2 | 2 | 2026-01-26 | 2026-01-20 | 8,500 |
| 3 | 4 | 2026-02-28 | 2026-02-20 | 6,800 |
| 4 | 6 | 2026-03-29 | unpaid | 6,200 |
| 5 | 7 | 2026-04-03 | 2026-03-25 | 9,100 |
| 6 | 8 | 2026-04-15 | unpaid | 9,600 |
| 7 | 10 | 2026-04-29 | 2026-04-20 | 5,200 |

Invoices 4 and 6 are overdue on 30 April 2026.

## Traps

- Order 3 is cancelled. Its item must not enter shipped revenue.
- Orders 5 and 9 are pending. Their items must not enter shipped revenue.
- The Monthly Subscription appears in order 5, which is pending, so it has no
  shipped sales.
- Counting order items instead of orders inflates the order count.
- Joining orders to order_items and then summing order totals counts each order
  once per item. Sum the item lines, or aggregate before joining.
- `COUNT(*)` after a left join counts the null row. Use `COUNT(customer_id)` or
  filter in the join.
- Date filters on `timestamptz` need an explicit boundary. April 2026 is
  `>= '2026-04-01'` and `< '2026-05-01'`, not `BETWEEN` with a midnight end.
