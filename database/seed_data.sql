-- database/seed_data.sql
-- Password is 'admin123' hashed with bcrypt
INSERT INTO users (username, email, hashed_password, is_admin) VALUES
('admin', 'admin@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzNBkrJ3zu', TRUE),
('reader', 'reader@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYzNBkrJ3zu', FALSE);

INSERT INTO series (name, description, min_value, max_value, color, icon, unit, created_by) VALUES
('Temperature Sensor 1', 'Living room temperature monitoring', -20.0, 50.0, '#EF4444', 'temperature-high', '°C', 1),
('Humidity Sensor 1', 'Living room humidity monitoring', 0.0, 100.0, '#3B82F6', 'droplet', '%', 1),
('Pressure Sensor', 'Atmospheric pressure', 900.0, 1100.0, '#10B981', 'gauge', 'hPa', 1);

-- Generate sample measurements for last 7 days
INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    1,
    20.0 + (random() * 5),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);

INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    2,
    45.0 + (random() * 20),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);

INSERT INTO measurements (series_id, value, timestamp, created_by)
SELECT
    3,
    1013.0 + (random() * 20 - 10),
    NOW() - (interval '1 hour' * generate_series(0, 168)),
    1
FROM generate_series(0, 168);
