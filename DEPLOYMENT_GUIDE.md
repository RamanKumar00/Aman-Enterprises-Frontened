# Backend Deployment Guide (Render.com)

Since you want to share your APK with others, your backend needs to be online (not just on your laptop). We recommended using **Render** as it is free and easy.

## Step 1: Push Backend to GitHub
1. Open your backend folder: `Aman Enterprises Backend\E-commerece-backend`
2. If it's not on GitHub yet:
   - Create a new repository on [GitHub.com](https://github.com/new) named `aman-enterprises-backend`.
   - Run these commands in your backend terminal:
     ```bash
     git remote add origin https://github.com/YOUR_USERNAME/aman-enterprises-backend.git
     git branch -M main
     git push -u origin main
     ```

## Step 2: Deploy on Render
1. Go to [dashboard.render.com](https://dashboard.render.com/).
2. Click **New +** -> **Web Service**.
3. Connect your GitHub account and select your `aman-enterprises-backend` repo.
4. **Settings**:
   - **Name**: `aman-enterprises-api` (or similar)
   - **Region**: Singapore (closest to India) or Germany.
   - **Branch**: `main`
   - **Root Directory**: `.` (leave empty)
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Free Plan**: Select "Free".

## Step 3: Add Environment Variables
Scroll down to "Environment Variables" and add these (copied from your `config.env`):

| Key | Value |
|-----|-------|
| `MONGO_URI` | `mongodb+srv://amanenterprises:R%40man9835@cluster0.qlzitfc.mongodb.net/amanenterprises?retryWrites=true&w=majority` |
| `JWT_SECRET_KEY` | `aman_enterprises_secret_key_2026` |
| `JWT_EXPIRES` | `7d` |
| `CLOUDINARY_CLOUD_NAME` | *(Add your Cloudinary Name)* |
| `CLOUDINARY_API_KEY` | *(Add your Cloudinary Key)* |
| `CLOUDINARY_API_SECRET` | *(Add your Cloudinary Secret)* |

> **Note**: Your local `config.env` had email settings (`SMTP_EMAIL`: `your_email@gmail.com`). If you want email features (OTP, etc.) to work, you MUST update those with real values in Render as well.

## Step 4: Get the URL
Once deployed, Render will give you a URL like:
`https://aman-enterprises-api.onrender.com`

## Step 5: Update App & Build APK
1. Copy that URL.
2. Send it to me (Antigravity).
3. I will update `lib/services/api_service.dart`.
4. I will build the Release APK for you.
