import { daysAgo } from "./id.util";
import { MockCustomer } from "./types";

/** Storefront customer directory, shown on the admin panel's "Customers" screen. */
interface CustomerSeedRow {
  name: string;
  city: string;
  joinedDaysAgo: number;
  orderCount: number;
  totalSpentPkr: number;
  status: "active" | "blocked";
}

const RAW: CustomerSeedRow[] = [
  { name: "Ayesha Khan", city: "Lahore", joinedDaysAgo: 410, orderCount: 14, totalSpentPkr: 86400, status: "active" },
  { name: "Bilal Ahmed", city: "Karachi", joinedDaysAgo: 365, orderCount: 9, totalSpentPkr: 52300, status: "active" },
  { name: "Sana Malik", city: "Islamabad", joinedDaysAgo: 298, orderCount: 21, totalSpentPkr: 138750, status: "active" },
  { name: "Hamza Tariq", city: "Faisalabad", joinedDaysAgo: 240, orderCount: 3, totalSpentPkr: 11200, status: "active" },
  { name: "Zainab Raza", city: "Lahore", joinedDaysAgo: 210, orderCount: 17, totalSpentPkr: 97650, status: "active" },
  { name: "Usman Farooq", city: "Rawalpindi", joinedDaysAgo: 180, orderCount: 1, totalSpentPkr: 3200, status: "blocked" },
  { name: "Mahnoor Iqbal", city: "Karachi", joinedDaysAgo: 165, orderCount: 6, totalSpentPkr: 34800, status: "active" },
  { name: "Ali Hassan", city: "Multan", joinedDaysAgo: 140, orderCount: 11, totalSpentPkr: 71500, status: "active" },
  { name: "Fatima Sheikh", city: "Lahore", joinedDaysAgo: 120, orderCount: 4, totalSpentPkr: 22400, status: "active" },
  { name: "Omar Siddiqui", city: "Karachi", joinedDaysAgo: 95, orderCount: 8, totalSpentPkr: 46900, status: "active" },
  { name: "Hira Yousaf", city: "Islamabad", joinedDaysAgo: 60, orderCount: 2, totalSpentPkr: 9800, status: "active" },
  { name: "Danish Aslam", city: "Peshawar", joinedDaysAgo: 30, orderCount: 0, totalSpentPkr: 0, status: "active" },
];

export const CUSTOMERS: MockCustomer[] = RAW.map((c, i) => {
  const emailHandle = c.name.toLowerCase().replace(/\s+/g, ".");
  return {
    id: `cust_${String(i + 1).padStart(3, "0")}`,
    name: c.name,
    email: `${emailHandle}@gmail.com`,
    phone: `+9230${((i % 9) + 1)}${String(1000000 + i * 7919).slice(-7)}`,
    city: c.city,
    avatarUrl: `https://api.dicebear.com/7.x/notionists/svg?seed=${encodeURIComponent(c.name)}`,
    joinedAt: daysAgo(c.joinedDaysAgo),
    orderCount: c.orderCount,
    totalSpentPkr: c.totalSpentPkr,
    status: c.status,
  };
});
