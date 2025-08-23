-- Update the sensor_readings_effective view to show battery data only to admins
CREATE OR REPLACE VIEW public.sensor_readings_effective AS
SELECT
  sr.id, sr.device_id, sr.timestamp,
  sr.temperature,
  sr.humidity,
  sr.pressure,
  CASE WHEN public.is_premium() THEN sr.co2 ELSE NULL END AS co2,
  CASE WHEN public.is_premium() THEN sr.light_veml7700 ELSE NULL END AS light_veml7700,
  CASE WHEN public.is_premium() THEN sr.light_tsl2591 ELSE NULL END AS light_tsl2591,
  CASE WHEN public.is_premium() THEN sr.acceleration_x ELSE NULL END AS acceleration_x,
  CASE WHEN public.is_premium() THEN sr.acceleration_y ELSE NULL END AS acceleration_y,
  CASE WHEN public.is_premium() THEN sr.acceleration_z ELSE NULL END AS acceleration_z,
  CASE WHEN public.is_premium() THEN sr.soil_capacitance ELSE NULL END AS soil_capacitance,
  -- Battery data only for admins (not premium users)
  CASE WHEN public.is_admin() THEN sr.battery_voltage ELSE NULL END AS battery_voltage,
  CASE WHEN public.is_admin() THEN sr.battery_percentage ELSE NULL END AS battery_percentage,
  CASE WHEN public.is_premium() THEN sr.dew_point ELSE NULL END AS dew_point,
  CASE WHEN public.is_premium() THEN sr.wet_bulb_temp ELSE NULL END AS wet_bulb_temp,
  CASE WHEN public.is_premium() THEN sr.heat_index ELSE NULL END AS heat_index,
  CASE WHEN public.is_premium() THEN sr.vpd ELSE NULL END AS vpd,
  CASE WHEN public.is_premium() THEN sr.absolute_humidity ELSE NULL END AS absolute_humidity,
  CASE WHEN public.is_premium() THEN sr.altitude ELSE NULL END AS altitude,
  CASE WHEN public.is_premium() THEN sr.weather_trend ELSE NULL END AS weather_trend,
  CASE WHEN public.is_premium() THEN sr.par ELSE NULL END AS par,
  CASE WHEN public.is_premium() THEN sr.soil_moisture_percentage ELSE NULL END AS soil_moisture_percentage,
  -- Battery health only for admins (not premium users)
  CASE WHEN public.is_admin() THEN sr.battery_health ELSE NULL END AS battery_health,
  CASE WHEN public.is_premium() THEN sr.shock_detected ELSE NULL END AS shock_detected,
  sr.created_at
FROM public.sensor_readings sr;
