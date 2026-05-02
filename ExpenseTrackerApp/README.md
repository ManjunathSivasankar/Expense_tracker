# 📱 Expense Tracker Application – Project README

---

## 📌 Project Overview

This project is a **customized Expense Tracker mobile application** designed to help users manage their financial activities in a **simple, fast, and structured way**.

Unlike generic expense apps, this application is specifically built to handle:

* **Personal expenses**
* **Business expenses**
* **Income tracking (both personal & business)**
* **Borrow & lend tracking**
* **Detailed financial insights**

The app is designed with a **minimal and user-friendly UI**, focusing on **quick data entry** and **clear financial visibility**.

---

## 🎯 Purpose of the Project

The main goal of this application is to solve real-life financial tracking problems such as:

* Difficulty in tracking daily expenses
* Mixing personal and business finances
* Lack of clarity on income vs expenditure
* No structured way to track borrowed/lent money
* No quick overview of financial status

This app provides a **centralized system** to manage all these aspects efficiently.

---

## 🧠 Problem Statement

Most expense tracking apps:

* Are too complex or overloaded with features
* Do not separate personal and business finances clearly
* Do not support customized workflows
* Lack fast entry systems
* Do not provide meaningful insights

---

## ✅ Solution Provided

This application solves the above problems by:

* Providing **clear separation** between personal, business, and income data
* Offering a **single toggle-based navigation system**
* Enabling **quick expense and income entry**
* Giving a **complete financial overview in one place**
* Supporting **custom categories and income sources**
* Working **fully offline using local storage**

---

## 🔁 Core Navigation Concept

The app uses a **single toggle system** with three modes:

* **Personal**
* **Business**
* **Income**

This ensures:

* Clean navigation
* No confusion between modules
* Easy switching between financial views

---

## 📱 Key Modules

---

### 1️⃣ Personal Module

Handles:

* Personal expenses
* Category-based tracking
* Monthly limits

Features:

* Daily & monthly expense tracking
* Category-wise limits
* Alerts for limit exceed
* Clean dashboard view

---

### 2️⃣ Business Module

Handles:

* Business-related expenses
* Product/service-based tracking

Features:

* Separate expense tracking
* No interference with personal data
* Business analytics overview

---

### 3️⃣ Income Module

Handles:

* Personal income (salary, freelance)
* Business income (sales, services)

Features:

* Unified income system
* Mandatory detailed entry
* Source-based tracking
* Income summaries (daily, weekly, monthly)

---

## 💸 Borrow & Lend Module

Tracks:

* Money given to others
* Money borrowed from others

Features:

* Add, edit, and view transactions
* Identify:

  * Who owes you
  * Whom you owe
* Maintain proper records

---

## 🗂️ Category & Source Management

### Categories:

* Add / Edit / Delete
* Personal & Business separation
* Limit setting

### Income Sources:

* Add / Edit / Delete
* Examples:

  * Salary
  * Freelance
  * Printing work
  * Product sales

---

## 📊 Dashboard Features

The dashboard is designed for **quick understanding and fast actions**.

### Layout Flow:

1. Quick Entry
2. Category List
3. Limits
4. Monthly Insights
5. Charts (Pie chart)
6. Combined Financial Summary

---

## 📈 Combined Financial Summary

A key feature that shows:

* Total Personal Expenses
* Total Business Expenses
* Total Personal Income
* Total Business Income
* Overall Income
* Overall Expenditure

👉 Provides a **complete financial snapshot in one place**

---

## 📜 History & Reports

Features:

* View all transactions
* Filter by:

  * Category
  * Date range
* Category-specific history view
* Monthly stored reports

---

## 📤 Export Feature

* Export data in **CSV format**
* Options:

  * Custom date range
  * Weekly
  * Monthly

---

## ⚙️ Technical Overview

* **Framework:** Flutter
* **Language:** Dart
* **Architecture:** Modular (Provider / MVVM recommended)
* **Database:** Local (SQLite / sqflite)
* **Offline Support:** Fully offline

---

## 🎨 UI/UX Design Principles

* Minimal design
* Fast interaction
* Clean layout
* Easy navigation
* No unnecessary complexity

Focus:
👉 “Enter data quickly → Understand instantly”

---

## 🔒 Data Handling

* All data stored locally on device
* No internet dependency
* No external APIs
* Data persists across updates

---

## 🚀 Expected Outcome

By the end of development, the application should:

* Provide a **complete financial management system**
* Be **easy to use for daily tracking**
* Offer **clear insights into income and expenses**
* Maintain **strict separation between personal and business data**
* Deliver a **smooth and efficient user experience**

---

## 📌 Summary

This is not just an expense tracker —
it is a **personalized financial management tool** designed for:

* Daily usage
* Business tracking
* Income monitoring
* Complete financial clarity

---

👉 The goal is simplicity, speed, and clarity — all in one application.

---

## 📲 How to Setup & Use on Mobile

Follow these steps to get the app running on your Android or iOS device:

### ⚙️ Prerequisites
* **Flutter SDK** installed on your machine.
* **USB Debugging** enabled on your Android device (or an active iOS Simulator).
* **VS Code** with Flutter and Dart extensions.

### 🛠️ Installation Steps
1. **Connect Your Device**: Connect your mobile phone via USB cable.
2. **Fetch Dependencies**: Open the project folder in VS Code and run:
   ```bash
   flutter pub get
   ```
3. **Run the App**:
   * Press `F5` in VS Code or run:
   ```bash
   flutter run
   ```
   * Select your connected device from the list.

### 💡 How to Use
1. **Switch Modes**: Use the **Toggle** at the top to switch between **Personal**, **Business**, and **Income**.
2. **Add Transaction**: Tap the **FAB (+)** at the bottom right to add an expense or income.
3. **Quick Entry**: Tap any **Category Card** on the dashboard for instant 1-second data entry.
4. **Manage Data**: Use the icons in the Top Bar to access **History**, **Revenue/Sources**, **Categories**, or **Borrow & Lend**.
5. **View Summary**: Scroll to the bottom of the dashboard to see your **Combined Financial Snapshot**.
