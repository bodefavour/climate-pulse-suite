# Climate Pulse Suite - Database Schema Documentation

## 📋 Overview

This document explains the database schema for the Climate Pulse Suite environmental monitoring application. The system uses Supabase (PostgreSQL) for data storage with Row Level Security (RLS) enabled.

## 🗃️ Database Tables

### 1. `public.profiles` - User Management & Subscriptions

**Purpose**: Stores user profile information, subscription tiers, and admin status.

```sql
CREATE TABLE public.profiles (
  id uuid NOT NULL,                                                          -- References auth.users(id)
  name text,                                                                 -- User's display name
  email text,                                                                -- User's email address
  created_at timestamp with time zone DEFAULT now(),                        -- Account creation timestamp
  updated_at timestamp with time zone DEFAULT now(),                        -- Last profile update
  subscription_tier subscription_tier NOT NULL DEFAULT 'free',              -- 🎯 SUBSCRIPTION STATUS
  is_admin boolean NOT NULL DEFAULT false,                                  -- 🎯 ADMIN PRIVILEGES
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
```

**Key Fields:**
- `subscription_tier`: ENUM ('free', 'premium') - Determines feature access
- `is_admin`: Boolean - Grants administrative privileges

### 2. `public.devices` - IoT Device Registry

**Purpose**: Stores registered environmental monitoring devices.

```sql
CREATE TABLE public.devices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),                               -- Internal device UUID
  device_id text NOT NULL UNIQUE,                                          -- Public device identifier
  name text NOT NULL,                                                       -- User-assigned device name
  owner_id uuid NOT NULL,                                                   -- References profiles(id)
  created_at timestamp with time zone DEFAULT now(),                       -- Device registration time
  updated_at timestamp with time zone DEFAULT now(),                       -- Last device update
  device_type text NOT NULL DEFAULT 'AIR' CHECK (device_type = ANY (ARRAY['AIR', 'SOIL'])), -- Device category
  CONSTRAINT devices_pkey PRIMARY KEY (id),
  CONSTRAINT devices_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.profiles(id)
);
```

**Device Types:**
- `AIR`: Environmental air quality sensors
- `SOIL`: Soil monitoring sensors

### 3. `public.sensor_readings` - Primary Sensor Data

**Purpose**: Stores comprehensive sensor readings from all devices.

```sql
CREATE TABLE public.sensor_readings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,                                                  -- References devices(id)
  timestamp timestamp with time zone NOT NULL DEFAULT now(),               -- Reading timestamp
  
  -- Basic Environmental Data (Free Tier)
  temperature double precision,                                             -- Temperature in °C
  humidity double precision,                                                -- Relative humidity %
  pressure double precision,                                                -- Atmospheric pressure (hPa)
  dew_point double precision,                                               -- Dew point temperature °C
  
  -- Advanced Environmental Data (Premium Tier)
  co2 double precision,                                                     -- CO2 concentration (ppm)
  vpd double precision,                                                     -- Vapor Pressure Deficit (kPa)
  heat_index double precision,                                              -- Heat index °C
  wet_bulb_temp double precision,                                           -- Wet bulb temperature °C
  absolute_humidity double precision,                                       -- Absolute humidity (g/m³)
  altitude double precision,                                                -- Altitude (m)
  weather_trend text,                                                       -- Weather trend analysis
  uv_index double precision,                                                -- UV index
  
  -- Light Sensors (Premium Tier)
  light_veml7700 double precision,                                          -- VEML7700 light sensor (lux)
  light_tsl2591 double precision,                                           -- TSL2591 light sensor (lux)
  par double precision,                                                     -- Photosynthetically Active Radiation (μmol/m²/s)
  
  -- Motion & Acceleration (Premium Tier)
  acceleration_x double precision,                                          -- X-axis acceleration (g)
  acceleration_y double precision,                                          -- Y-axis acceleration (g)
  acceleration_z double precision,                                          -- Z-axis acceleration (g)
  shock_detected boolean,                                                   -- Shock detection flag
  
  -- Soil Monitoring (Premium Tier)
  soil_capacitance double precision,                                        -- Soil capacitance sensor
  soil_moisture_percentage double precision,                                -- Calculated soil moisture %
  
  -- Device Status (Admin Only)
  battery_voltage double precision,                                         -- Battery voltage (V)
  battery_percentage double precision,                                      -- Battery level %
  battery_health double precision,                                          -- Battery health %
  
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT sensor_readings_pkey PRIMARY KEY (id),
  CONSTRAINT sensor_readings_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id)
);
```

### 4. `public.readings` - Legacy Sensor Data

**Purpose**: Legacy table for basic sensor readings (still in use for backward compatibility).

```sql
CREATE TABLE public.readings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  device_id uuid NOT NULL,                                                  -- References devices(id)
  timestamp timestamp with time zone DEFAULT now(),
  temperature double precision NOT NULL,
  humidity double precision NOT NULL,
  pressure double precision NOT NULL,
  dew_point double precision NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT readings_pkey PRIMARY KEY (id),
  CONSTRAINT readings_device_id_fkey FOREIGN KEY (device_id) REFERENCES public.devices(id)
);
```

### 5. `public.user_roles` - Role-Based Access Control

**Purpose**: Additional role management for fine-grained permissions.

```sql
CREATE TABLE public.user_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,                                                    -- References auth.users(id)
  role app_role NOT NULL,                                                   -- ENUM ('admin', 'user')
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT user_roles_pkey PRIMARY KEY (id),
  CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
```

## 🎭 Data Access Control

### Subscription Tiers

#### Free Tier (`subscription_tier = 'free'`)
**Available Data:**
- Temperature, Humidity, Pressure
- Dew Point
- Basic CO2 readings

#### Premium Tier (`subscription_tier = 'premium'`)
**Additional Data:**
- Advanced environmental metrics (VPD, Heat Index, etc.)
- Light sensors and PAR
- Soil moisture monitoring
- Motion and acceleration data
- Weather trend analysis
- UV index

#### Admin Only (`is_admin = true`)
**Exclusive Data:**
- Battery voltage, percentage, and health
- Device diagnostic information
- Full system access

### Access Control Functions

```sql
-- Check if user has premium access
SELECT public.is_premium(); -- Returns true for premium users OR admins

-- Check if user has admin privileges  
SELECT public.is_admin(); -- Returns true for admin users only

-- Check specific role
SELECT public.has_role(auth.uid(), 'admin'); -- Check for specific role
```

### Data Filtering View

The `public.sensor_readings_effective` view automatically filters data based on user subscription:

```sql
-- Example: Battery data only visible to admins
CASE WHEN public.is_admin() THEN sr.battery_voltage ELSE NULL END AS battery_voltage

-- Example: Premium data only visible to premium users
CASE WHEN public.is_premium() THEN sr.co2 ELSE NULL END AS co2
```

## 🔧 Database Functions

### User Management Functions

- `public.is_premium()`: Returns true if user has premium subscription OR admin privileges
- `public.is_admin()`: Returns true if user has admin privileges
- `public.has_role(user_id, role)`: Checks if user has specific role
- `public.handle_new_user()`: Trigger function to create profile on user registration

## 📊 Common Queries

### Check Subscription Status
```sql
-- View all users and their subscription status
SELECT 
  name,
  email,
  subscription_tier,
  is_admin,
  created_at
FROM public.profiles
ORDER BY created_at DESC;
```

### Subscription Analytics
```sql
-- Count users by subscription tier
SELECT 
  subscription_tier,
  COUNT(*) as user_count
FROM public.profiles
GROUP BY subscription_tier;
```

### Device Overview
```sql
-- List all devices with owner information
SELECT 
  d.name as device_name,
  d.device_id,
  d.device_type,
  p.name as owner_name,
  p.subscription_tier
FROM public.devices d
JOIN public.profiles p ON d.owner_id = p.id
ORDER BY d.created_at DESC;
```

### Recent Sensor Data
```sql
-- Get latest readings for all devices
SELECT 
  d.name as device_name,
  sr.temperature,
  sr.humidity,
  sr.pressure,
  sr.timestamp
FROM public.sensor_readings sr
JOIN public.devices d ON sr.device_id = d.id
WHERE sr.timestamp > NOW() - INTERVAL '24 hours'
ORDER BY sr.timestamp DESC;
```

## 🔒 Security Features

### Row Level Security (RLS)
All tables have RLS enabled with policies ensuring:
- Users can only access their own data
- Admins have full access to all data
- Premium features are properly gated

### Data Privacy
- Battery and diagnostic data is admin-only
- Premium features require subscription
- Personal data is isolated per user

## 🚀 Subscription Management

### Updating Subscription Status
```sql
-- Upgrade user to premium
UPDATE public.profiles 
SET subscription_tier = 'premium', updated_at = NOW()
WHERE id = 'user-uuid-here';

-- Grant admin privileges
UPDATE public.profiles 
SET is_admin = true, updated_at = NOW()
WHERE id = 'user-uuid-here';
```

### Bulk Operations
```sql
-- Find all premium users
SELECT email, name FROM public.profiles WHERE subscription_tier = 'premium';

-- Find admin users
SELECT email, name FROM public.profiles WHERE is_admin = true;
```

---

## 📝 Notes

- The system uses both `readings` (legacy) and `sensor_readings` (current) tables
- Data access is controlled at the database level for security
- Subscription status determines feature availability
- Admin users have access to all data regardless of subscription tier
- All timestamps are stored in UTC with timezone information
