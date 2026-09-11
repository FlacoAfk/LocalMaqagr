-- ============================================================
-- MaqAgr Supabase Migration - full schema + data
-- Replaces any existing local schema with the Supabase version.
-- Idempotent: DROP IF EXISTS + CREATE + INSERT.
-- ============================================================

BEGIN;

-- Drop all existing tables (cascade to handle FKs)
DROP TABLE IF EXISTS password_reset_tokens CASCADE;
DROP TABLE IF EXISTS query_history CASCADE;
DROP TABLE IF EXISTS recommendation CASCADE;
DROP TABLE IF EXISTS power_loss CASCADE;
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS query CASCADE;
DROP TABLE IF EXISTS implement CASCADE;
DROP TABLE IF EXISTS tractor CASCADE;
DROP TABLE IF EXISTS terrain CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS role CASCADE;

-- Drop sequences if they exist (will be recreated by dump)
DROP SEQUENCE IF EXISTS implement_implement_id_seq CASCADE;
DROP SEQUENCE IF EXISTS notification_notification_id_seq CASCADE;
DROP SEQUENCE IF EXISTS power_loss_power_loss_id_seq CASCADE;
DROP SEQUENCE IF EXISTS query_history_history_id_seq CASCADE;
DROP SEQUENCE IF EXISTS query_query_id_seq CASCADE;
DROP SEQUENCE IF EXISTS recommendation_recommendation_id_seq CASCADE;
DROP SEQUENCE IF EXISTS role_role_id_seq CASCADE;
DROP SEQUENCE IF EXISTS terrain_terrain_id_seq CASCADE;
DROP SEQUENCE IF EXISTS tractor_tractor_id_seq CASCADE;
DROP SEQUENCE IF EXISTS users_user_id_seq CASCADE;

-- === Begin Supabase dump ===
--
-- PostgreSQL database dump
--



-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- Schema public already exists in a fresh database; skip creation.
-- CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: implement; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.implement (
    implement_id integer NOT NULL,
    implement_name character varying(150) NOT NULL,
    brand character varying(100) NOT NULL,
    power_requirement_hp double precision NOT NULL,
    working_width_m double precision NOT NULL,
    soil_type character varying(100),
    working_depth_cm double precision,
    weight_kg double precision,
    implement_type character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'available'::character varying,
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    image_url text,
    CONSTRAINT implement_image_url_valid CHECK (((image_url IS NULL) OR (image_url ~* '^(https?://|/uploads/)'::text)))
);


--
-- Name: implement_implement_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.implement_implement_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: implement_implement_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.implement_implement_id_seq OWNED BY public.implement.implement_id;


--
-- Name: notification; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification (
    notification_id integer NOT NULL,
    user_id integer,
    type character varying(50) NOT NULL,
    title character varying(255) NOT NULL,
    message text,
    data jsonb,
    read boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: notification_notification_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notification_notification_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_notification_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notification_notification_id_seq OWNED BY public.notification.notification_id;


--
-- Name: power_loss; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.power_loss (
    power_loss_id integer NOT NULL,
    query_id integer NOT NULL,
    slope_loss_hp double precision,
    altitude_loss_hp double precision,
    rolling_resistance_loss_hp double precision,
    slippage_loss_hp double precision,
    total_loss_hp double precision NOT NULL,
    available_power_hp double precision NOT NULL,
    net_power_hp double precision NOT NULL,
    efficiency_percentage double precision,
    calculation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: power_loss_power_loss_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.power_loss_power_loss_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: power_loss_power_loss_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.power_loss_power_loss_id_seq OWNED BY public.power_loss.power_loss_id;


--
-- Name: query; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query (
    query_id integer NOT NULL,
    user_id integer NOT NULL,
    terrain_id integer NOT NULL,
    tractor_id integer NOT NULL,
    implement_id integer,
    pto_distance_m double precision,
    carried_objects_weight_kg double precision DEFAULT 0,
    working_speed_kmh double precision,
    query_type character varying(50) NOT NULL,
    query_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'completed'::character varying,
    CONSTRAINT query_query_type_check CHECK (((query_type)::text = ANY ((ARRAY['power_loss'::character varying, 'minimum_power'::character varying, 'recommendation'::character varying])::text[])))
);


--
-- Name: query_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.query_history (
    history_id integer NOT NULL,
    user_id integer NOT NULL,
    query_id integer,
    action_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    action_type character varying(50) NOT NULL,
    description text,
    result_json jsonb
);


--
-- Name: query_history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_history_history_id_seq OWNED BY public.query_history.history_id;


--
-- Name: query_query_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.query_query_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_query_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.query_query_id_seq OWNED BY public.query.query_id;


--
-- Name: recommendation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recommendation (
    recommendation_id integer NOT NULL,
    user_id integer NOT NULL,
    terrain_id integer NOT NULL,
    tractor_id integer,
    implement_id integer,
    compatibility_score double precision,
    observations text,
    work_type character varying(100),
    recommendation_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: recommendation_recommendation_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recommendation_recommendation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recommendation_recommendation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recommendation_recommendation_id_seq OWNED BY public.recommendation.recommendation_id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role (
    role_id integer NOT NULL,
    role_name character varying(50) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    CONSTRAINT role_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[])))
);


--
-- Name: role_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;


--
-- Name: terrain; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terrain (
    terrain_id integer NOT NULL,
    user_id integer,
    name character varying(150) NOT NULL,
    area_hectares double precision,
    altitude_meters double precision NOT NULL,
    slope_percentage double precision NOT NULL,
    soil_type character varying(100) NOT NULL,
    temperature_celsius double precision,
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    status character varying(20) DEFAULT 'active'::character varying
);


--
-- Name: terrain_terrain_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terrain_terrain_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: terrain_terrain_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terrain_terrain_id_seq OWNED BY public.terrain.terrain_id;


--
-- Name: tractor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tractor (
    tractor_id integer NOT NULL,
    name character varying(150) NOT NULL,
    brand character varying(100) NOT NULL,
    model character varying(100) NOT NULL,
    model_year integer,
    engine_power_hp double precision NOT NULL,
    price double precision,
    weight_kg double precision NOT NULL,
    traction_force_kn double precision NOT NULL,
    traction_type character varying(50) NOT NULL,
    tire_type character varying(100),
    tire_width_mm double precision,
    tire_diameter_mm double precision,
    tire_pressure_psi double precision,
    price_usd double precision,
    fuel_consumption_lph double precision,
    maintenance_cost_per_hour double precision,
    status character varying(20) DEFAULT 'available'::character varying,
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    image_url text,
    CONSTRAINT tractor_image_url_valid CHECK (((image_url IS NULL) OR (image_url ~* '^(https?://|/uploads/)'::text))),
    CONSTRAINT tractor_traction_type_check CHECK (((traction_type)::text = ANY ((ARRAY['4x2'::character varying, '4x4'::character varying, 'track'::character varying])::text[])))
);


--
-- Name: tractor_tractor_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tractor_tractor_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tractor_tractor_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tractor_tractor_id_seq OWNED BY public.tractor.tractor_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    password character varying(255) NOT NULL,
    role_id integer NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_session timestamp without time zone,
    CONSTRAINT users_status_check CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying])::text[])))
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: implement implement_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implement ALTER COLUMN implement_id SET DEFAULT nextval('public.implement_implement_id_seq'::regclass);


--
-- Name: notification notification_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification ALTER COLUMN notification_id SET DEFAULT nextval('public.notification_notification_id_seq'::regclass);


--
-- Name: power_loss power_loss_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.power_loss ALTER COLUMN power_loss_id SET DEFAULT nextval('public.power_loss_power_loss_id_seq'::regclass);


--
-- Name: query query_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query ALTER COLUMN query_id SET DEFAULT nextval('public.query_query_id_seq'::regclass);


--
-- Name: query_history history_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_history ALTER COLUMN history_id SET DEFAULT nextval('public.query_history_history_id_seq'::regclass);


--
-- Name: recommendation recommendation_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation ALTER COLUMN recommendation_id SET DEFAULT nextval('public.recommendation_recommendation_id_seq'::regclass);


--
-- Name: role role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role ALTER COLUMN role_id SET DEFAULT nextval('public.role_role_id_seq'::regclass);


--
-- Name: terrain terrain_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terrain ALTER COLUMN terrain_id SET DEFAULT nextval('public.terrain_terrain_id_seq'::regclass);


--
-- Name: tractor tractor_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tractor ALTER COLUMN tractor_id SET DEFAULT nextval('public.tractor_tractor_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: implement; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.implement (implement_id, implement_name, brand, power_requirement_hp, working_width_m, soil_type, working_depth_cm, weight_kg, implement_type, status, registration_date, image_url) VALUES
	(1, '3-body disc plow', 'Baldan', 50, 0.9, 'Loam', NULL, NULL, 'plow', 'available', '2026-04-21 06:46:20.86626', '/uploads/implements/baldan-3body-disc-plow.jpg'),
	(2, '20-disc harrow', 'Tatu', 35, 1.8, 'All', NULL, NULL, 'harrow', 'available', '2026-04-21 06:46:20.86626', '/uploads/implements/tatu-20disc-harrow.jpg'),
	(3, '5-row seeder', 'Semeato', 40, 1.5, 'Loam', NULL, NULL, 'seeder', 'available', '2026-04-21 06:46:20.86626', '/uploads/implements/semeato-5row-seeder.jpg'),
	(4, 'Test Implement Admin UPDATED', 'AdminImpl', 65, 2.5, NULL, NULL, NULL, 'cultivator', 'inactive', '2026-04-21 12:23:50.2748', '/uploads/implements/generic-cultivator-adminimpl.jpg');


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.notification (notification_id, user_id, type, title, message, data, read, created_at) VALUES
	(1, 1, 'tractor_available', 'Tractor disponible', 'El tractor Tractor Direct Upload ahora se encuentra disponible.', '{"tractorId": 7}', true, '2026-05-20 14:46:19.315413+00');


--
-- Data for Name: power_loss; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.power_loss (power_loss_id, query_id, slope_loss_hp, altitude_loss_hp, rolling_resistance_loss_hp, slippage_loss_hp, total_loss_hp, available_power_hp, net_power_hp, efficiency_percentage, calculation_date) VALUES
	(1, 2, 1.21, 0.88, 1.8, 0.6, 15.43, 75, 59.57, 79.42, '2026-04-21 20:41:50.313574'),
	(2, 3, 1.21, 0.88, 1.8, 0.6, 15.43, 75, 59.57, 79.42, '2026-04-21 20:43:47.669873'),
	(3, 4, 1.21, 0.88, 1.8, 0.6, 15.43, 75, 59.57, 79.42, '2026-04-21 20:44:36.170109'),
	(4, 5, 1.21, 0.88, 1.8, 0, 14.83, 75, 60.17, 80.22, '2026-04-29 21:52:47.060598'),
	(5, 6, 1.21, 0.88, 1.8, 0, 14.83, 75, 60.17, 80.22, '2026-04-29 21:52:54.678982');


--
-- Data for Name: query; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.query (query_id, user_id, terrain_id, tractor_id, implement_id, pto_distance_m, carried_objects_weight_kg, working_speed_kmh, query_type, query_date, status) VALUES
	(1, 1, 1, 1, 1, NULL, 0, NULL, 'minimum_power', '2026-04-21 20:29:40.744101', 'completed'),
	(2, 1, 1, 1, NULL, NULL, 0, 7.5, 'power_loss', '2026-04-21 20:41:50.313574', 'completed'),
	(3, 1, 1, 1, NULL, NULL, 0, 7.5, 'power_loss', '2026-04-21 20:43:47.669873', 'completed'),
	(4, 1, 1, 1, NULL, NULL, 0, 7.5, 'power_loss', '2026-04-21 20:44:36.170109', 'completed'),
	(5, 6, 1, 1, NULL, NULL, 0, 7.5, 'power_loss', '2026-04-29 21:52:47.060598', 'completed'),
	(6, 6, 1, 1, NULL, NULL, 0, 7.5, 'power_loss', '2026-04-29 21:52:54.678982', 'completed');


--
-- Data for Name: query_history; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.query_history (history_id, user_id, query_id, action_date, action_type, description, result_json) VALUES
	(1, 1, 1, '2026-04-21 20:29:40.744101', 'minimum_power_calculation', 'Cálculo de potencia mínima: 3-body disc plow en Campo La Esperanza', '{"queryId": 1, "tractorAnalysis": {"optimalCount": 0, "totalEvaluated": 7, "overpoweredCount": 2, "insufficientCount": 1}, "powerRequirement": {"input": {"terrainData": {"soil_type": "loam", "slope_percentage": 5}, "implementData": {"working_depth_m": 0.25, "power_requirement_hp": 50}}, "factors": {"soilFactor": 1, "basePowerHP": 50, "depthFactor": 1, "slopeFactor": 1.025, "safetyMargin": 0.15}, "minimumPowerHP": 58.94, "calculatedPowerHP": 51.25}, "topRecommendations": [{"name": "John Deere 5075E", "score": "OVERPOWERED", "tractor_id": 1}, {"name": "Massey Ferguson 4709", "score": "OVERPOWERED", "tractor_id": 2}]}'),
	(2, 1, 2, '2026-04-21 20:41:50.313574', 'calculation', 'Cálculo de potencia: John Deere 5075E en Campo La Esperanza', '{"queryId": 2, "netPower": 59.57, "efficiency": 79.42}'),
	(3, 1, 3, '2026-04-21 20:43:47.669873', 'calculation', 'Cálculo de potencia: John Deere 5075E en Campo La Esperanza', '{"queryId": 3, "netPower": 59.57, "efficiency": 79.42}'),
	(4, 1, 4, '2026-04-21 20:44:36.170109', 'calculation', 'Cálculo de potencia: John Deere 5075E en Campo La Esperanza', '{"queryId": 4, "netPower": 59.57, "efficiency": 79.42}'),
	(5, 6, 5, '2026-04-29 21:52:47.060598', 'calculation', 'Cálculo de potencia: John Deere 5075E en Campo La Esperanza', '{"queryId": 5, "netPower": 60.17, "efficiency": 80.22}'),
	(6, 6, 6, '2026-04-29 21:52:54.678982', 'calculation', 'Cálculo de potencia: John Deere 5075E en Campo La Esperanza', '{"queryId": 6, "netPower": 60.17, "efficiency": 80.22}');


--
-- Data for Name: recommendation; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.role (role_id, role_name, description, status, created_at, updated_at) VALUES
	(1, 'admin', 'System administrator with all permissions', 'active', '2026-04-21 06:46:20.86626', NULL),
	(2, 'user', 'Standard user with basic permissions', 'active', '2026-04-21 06:46:20.86626', NULL),
	(3, 'operator', 'Operator with query and calculation permissions', 'active', '2026-04-21 06:46:20.86626', NULL);


--
-- Data for Name: terrain; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.terrain (terrain_id, user_id, name, area_hectares, altitude_meters, slope_percentage, soil_type, temperature_celsius, registration_date, status) VALUES
	(1, 1, 'Campo La Esperanza', 50, 350, 5, 'Loam', 25, '2026-04-21 20:29:31.538372', 'active'),
	(2, 1, 'Finca El Porvenir', 120, 800, 15, 'Clay', 18, '2026-04-21 20:29:31.653629', 'active'),
	(3, 1, 'Lote San Martín', 35, 150, 2, 'Sand', 28, '2026-04-21 20:29:31.757174', 'active'),
	(4, 1, 'Parcela La Unión', 75, 1200, 25, 'Loam', 15, '2026-04-21 20:29:31.861971', 'active'),
	(5, 1, 'Terreno Las Colinas', 200, 500, 10, 'Loam', 22, '2026-04-21 20:29:31.966866', 'active');


--
-- Data for Name: tractor; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tractor (tractor_id, name, brand, model, model_year, engine_power_hp, price, weight_kg, traction_force_kn, traction_type, tire_type, tire_width_mm, tire_diameter_mm, tire_pressure_psi, price_usd, fuel_consumption_lph, maintenance_cost_per_hour, status, registration_date, image_url) VALUES
	(7, 'Tractor Direct Upload', 'DirectBrand', 'DU-200', 2025, 95, 68000, 3200, 42, '4x2', NULL, NULL, NULL, NULL, 68000, NULL, NULL, 'inactive', '2026-04-21 19:50:52.988102', '/uploads/tractors/generic-tractor-directbrand.jpg'),
	(1, 'John Deere test', 'John Deere', '5075E', 2023, 75, 65000, 3200, 45, '4x4', 'Radial 16.9R30', NULL, NULL, NULL, 65000, 12.5, 5, 'inactive', '2026-04-21 06:46:20.86626', '/uploads/tractors/john-deere-5075e.jpg'),
	(6, 'John Deere 8005F', 'TestBrand', 'TI-100', 2025, 110, 75000, 3800, 58, '4x4', NULL, NULL, NULL, NULL, 75000, NULL, NULL, 'inactive', '2026-04-21 19:50:52.298049', '/uploads/tractors/kiw1ljikzndrksp91ypk.jpg'),
	(2, 'Massey Ferguson 4709', 'Massey Ferguson', '4709', 2022, 90, 72000, 3500, 52, '4x4', 'Radial 18.4R34', NULL, NULL, NULL, 72000, 15, 6.5, 'available', '2026-04-21 06:46:20.86626', '/uploads/tractors/massey-ferguson-4709.jpg'),
	(3, 'New Holland TT3.55', 'New Holland', 'TT3.55', 2024, 55, 54000, 2800, 38, '4x2', 'Diagonal 14.9-28', NULL, NULL, NULL, 54000, 9.8, 4.2, 'available', '2026-04-21 06:46:20.86626', '/uploads/tractors/new-holland-tt355.jpg'),
	(5, 'Test Tractor Admin UPDATED', 'AdminBrand', 'AT-500', 2025, 130, 85000, 4000, 55, '4x4', NULL, NULL, NULL, NULL, 85000, NULL, NULL, 'inactive', '2026-04-21 12:23:49.667841', '/uploads/tractors/generic-tractor-adminbrand.jpg');


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (user_id, name, email, password, role_id, status, registration_date, last_session) VALUES
	(1, 'Administrator', 'admin@maqagr.com', '$2b$10$7kCdWH1tnn0EF1Fkba2g1unog29kedAsLL6shlx.AkRyNZah6gWlm', 1, 'active', '2026-04-21 06:46:20.86626', '2026-06-17 22:08:16.274636'),
	(6, 'waos', 'waos@waos.com', '$2b$10$J/yUt2qM9cLm7tq21pZqeOkrvD7BLYeNDSLguWbmjzzWGT2YkBec6', 2, 'active', '2026-04-26 18:19:25.028408', '2026-06-17 22:08:21.507454'),
	(7, 'Adminwaos', 'waos@admin.com', '$2b$10$FeVI9QtrOXMI7aMWMCx2EO5mKjN4kngL3cTQBAr2lNX2emnOWRPAu', 2, 'active', '2026-05-13 15:50:01.395958', '2026-06-17 22:08:21.790129'),
	(8, 'Local Admin', 'admin@local.dev', '$2b$10$oU95EN/FCh9uWXwGwqkb/elQNnBwfp45R7K23FHj1iKyQKBEBaMi2', 2, 'active', '2026-06-11 22:35:56.789245', '2026-06-17 22:08:22.062549');


--
-- Name: implement_implement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implement_implement_id_seq', 4, true);


--
-- Name: notification_notification_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notification_notification_id_seq', 1, true);


--
-- Name: power_loss_power_loss_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.power_loss_power_loss_id_seq', 5, true);


--
-- Name: query_history_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.query_history_history_id_seq', 6, true);


--
-- Name: query_query_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.query_query_id_seq', 6, true);


--
-- Name: recommendation_recommendation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recommendation_recommendation_id_seq', 1, false);


--
-- Name: role_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_role_id_seq', 4, true);


--
-- Name: terrain_terrain_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.terrain_terrain_id_seq', 5, true);


--
-- Name: tractor_tractor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tractor_tractor_id_seq', 7, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_user_id_seq', 8, true);


--
-- Name: implement implement_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.implement
    ADD CONSTRAINT implement_pkey PRIMARY KEY (implement_id);


--
-- Name: notification notification_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_pkey PRIMARY KEY (notification_id);


--
-- Name: power_loss power_loss_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.power_loss
    ADD CONSTRAINT power_loss_pkey PRIMARY KEY (power_loss_id);


--
-- Name: query_history query_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_history
    ADD CONSTRAINT query_history_pkey PRIMARY KEY (history_id);


--
-- Name: query query_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query
    ADD CONSTRAINT query_pkey PRIMARY KEY (query_id);


--
-- Name: recommendation recommendation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation
    ADD CONSTRAINT recommendation_pkey PRIMARY KEY (recommendation_id);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);


--
-- Name: role role_role_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_role_name_key UNIQUE (role_name);


--
-- Name: terrain terrain_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terrain
    ADD CONSTRAINT terrain_pkey PRIMARY KEY (terrain_id);


--
-- Name: tractor tractor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tractor
    ADD CONSTRAINT tractor_pkey PRIMARY KEY (tractor_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: idx_history_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_history_date ON public.query_history USING btree (action_date);


--
-- Name: idx_history_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_history_user ON public.query_history USING btree (user_id);


--
-- Name: idx_implement_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_implement_status ON public.implement USING btree (status);


--
-- Name: idx_implement_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_implement_type ON public.implement USING btree (implement_type);


--
-- Name: idx_notification_user_unread; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_notification_user_unread ON public.notification USING btree (user_id, read) WHERE (read = false);


--
-- Name: idx_query_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_query_date ON public.query USING btree (query_date);


--
-- Name: idx_query_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_query_type ON public.query USING btree (query_type);


--
-- Name: idx_query_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_query_user ON public.query USING btree (user_id);


--
-- Name: idx_role_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_role_name ON public.role USING btree (role_name);


--
-- Name: idx_terrain_soil_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terrain_soil_type ON public.terrain USING btree (soil_type);


--
-- Name: idx_terrain_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terrain_status ON public.terrain USING btree (status);


--
-- Name: idx_tractor_brand_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tractor_brand_model ON public.tractor USING btree (brand, model);


--
-- Name: idx_tractor_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tractor_status ON public.tractor USING btree (status);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role ON public.users USING btree (role_id);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: notification notification_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification
    ADD CONSTRAINT notification_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: power_loss power_loss_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.power_loss
    ADD CONSTRAINT power_loss_query_id_fkey FOREIGN KEY (query_id) REFERENCES public.query(query_id) ON DELETE CASCADE;


--
-- Name: query_history query_history_query_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_history
    ADD CONSTRAINT query_history_query_id_fkey FOREIGN KEY (query_id) REFERENCES public.query(query_id) ON DELETE SET NULL;


--
-- Name: query_history query_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query_history
    ADD CONSTRAINT query_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: query query_implement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query
    ADD CONSTRAINT query_implement_id_fkey FOREIGN KEY (implement_id) REFERENCES public.implement(implement_id) ON DELETE SET NULL;


--
-- Name: query query_terrain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query
    ADD CONSTRAINT query_terrain_id_fkey FOREIGN KEY (terrain_id) REFERENCES public.terrain(terrain_id) ON DELETE CASCADE;


--
-- Name: query query_tractor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query
    ADD CONSTRAINT query_tractor_id_fkey FOREIGN KEY (tractor_id) REFERENCES public.tractor(tractor_id) ON DELETE CASCADE;


--
-- Name: query query_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.query
    ADD CONSTRAINT query_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: recommendation recommendation_implement_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation
    ADD CONSTRAINT recommendation_implement_id_fkey FOREIGN KEY (implement_id) REFERENCES public.implement(implement_id) ON DELETE SET NULL;


--
-- Name: recommendation recommendation_terrain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation
    ADD CONSTRAINT recommendation_terrain_id_fkey FOREIGN KEY (terrain_id) REFERENCES public.terrain(terrain_id) ON DELETE CASCADE;


--
-- Name: recommendation recommendation_tractor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation
    ADD CONSTRAINT recommendation_tractor_id_fkey FOREIGN KEY (tractor_id) REFERENCES public.tractor(tractor_id) ON DELETE SET NULL;


--
-- Name: recommendation recommendation_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recommendation
    ADD CONSTRAINT recommendation_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: terrain terrain_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terrain
    ADD CONSTRAINT terrain_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(role_id) ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--





COMMIT;

-- ============================================================
-- Migración a imágenes locales (100% offline)
-- Las imágenes viven en {commonappdata}\MaqAgr\uploads (instaladas por el setup).
-- Relajar CHECK constraints y apuntar image_url a rutas locales.
-- Idempotente: los UPDATE solo tocan filas que aún apuntan a http(s).
-- ============================================================
BEGIN;
ALTER TABLE public.tractor DROP CONSTRAINT IF EXISTS tractor_image_url_valid;
ALTER TABLE public.implement DROP CONSTRAINT IF EXISTS implement_image_url_valid;
ALTER TABLE public.tractor ADD CONSTRAINT tractor_image_url_valid CHECK (image_url IS NULL OR image_url ~* '^(https?://|/uploads/)');
ALTER TABLE public.implement ADD CONSTRAINT implement_image_url_valid CHECK (image_url IS NULL OR image_url ~* '^(https?://|/uploads/)');

-- Tractores
UPDATE public.tractor SET image_url = '/uploads/tractors/john-deere-5075e.jpg' WHERE tractor_id = 1 AND image_url LIKE 'http%';
UPDATE public.tractor SET image_url = '/uploads/tractors/massey-ferguson-4709.jpg' WHERE tractor_id = 2 AND image_url LIKE 'http%';
UPDATE public.tractor SET image_url = '/uploads/tractors/new-holland-tt355.jpg' WHERE tractor_id = 3 AND image_url LIKE 'http%';
UPDATE public.tractor SET image_url = '/uploads/tractors/generic-tractor-adminbrand.jpg' WHERE tractor_id = 5 AND image_url LIKE 'http%';
UPDATE public.tractor SET image_url = '/uploads/tractors/kiw1ljikzndrksp91ypk.jpg' WHERE tractor_id = 6 AND image_url LIKE 'http%';
UPDATE public.tractor SET image_url = '/uploads/tractors/generic-tractor-directbrand.jpg' WHERE tractor_id = 7 AND image_url LIKE 'http%';

-- Implementos
UPDATE public.implement SET image_url = '/uploads/implements/baldan-3body-disc-plow.jpg' WHERE implement_id = 1 AND image_url LIKE 'http%';
UPDATE public.implement SET image_url = '/uploads/implements/tatu-20disc-harrow.jpg' WHERE implement_id = 2 AND image_url LIKE 'http%';
UPDATE public.implement SET image_url = '/uploads/implements/semeato-5row-seeder.jpg' WHERE implement_id = 3 AND image_url LIKE 'http%';
UPDATE public.implement SET image_url = '/uploads/implements/generic-cultivator-adminimpl.jpg' WHERE implement_id = 4 AND image_url LIKE 'http%';
COMMIT;

