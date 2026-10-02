--
-- PostgreSQL database dump
--

\restrict wK3p4Cv6HtfseAOql2hHYKfRzp9ckCIIRm3thpQQiTXBTS5dSBGHPjUD38houjd

-- Dumped from database version 17.10
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
    n_tines integer,
    ficha_pdf_url character varying(500),
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
    CONSTRAINT query_query_type_valid CHECK (((query_type)::text = ANY ((ARRAY['power_loss'::character varying, 'direct_power_loss'::character varying, 'minimum_power'::character varying, 'direct_minimum_power'::character varying, 'recommendation'::character varying, 'implement_power'::character varying])::text[])))
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
    CONSTRAINT role_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text])))
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
    status character varying(20) DEFAULT 'active'::character varying,
    soil_condition character varying(10),
    CONSTRAINT terrain_soil_condition_check CHECK (((soil_condition)::text = ANY ((ARRAY['bueno'::character varying, 'medio'::character varying, 'malo'::character varying])::text[])))
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
    has_turbo boolean DEFAULT false NOT NULL,
    ficha_pdf_url character varying(500),
    prioridad boolean DEFAULT false,
    CONSTRAINT tractor_image_url_valid CHECK (((image_url IS NULL) OR (image_url ~* '^(https?://|/uploads/)'::text))),
    CONSTRAINT tractor_traction_type_check CHECK (((traction_type)::text = ANY (ARRAY[('4x2'::character varying)::text, ('4x4'::character varying)::text, ('track'::character varying)::text])))
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
    CONSTRAINT users_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text, ('suspended'::character varying)::text])))
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

COPY public.implement (implement_id, implement_name, brand, power_requirement_hp, working_width_m, soil_type, working_depth_cm, weight_kg, implement_type, status, registration_date, image_url, n_tines, ficha_pdf_url) FROM stdin;
6	Abonador Hidráulico para Labranza de Conservación 2 discos	Baldan	54	2.25	Franco	\N	320	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-1.webp	2	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
48	Rastra Aradora Intermediaria Control Remoto Plegable 48 discos	Baldan	295.5	6.39	Franco	\N	5461	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-a-rastra-aradora-intermediaria-control-remoto-plegable-3.webp	48	https://baldan.com.br/es/productos/cri-a-rastra-aradora-intermediaria-control-remoto-plegable/
7	Abonador Hidráulico para Labranza de Conservación 4 discos	Baldan	80	3.65	Franco	\N	511	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-7.webp	4	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
8	Abonador Hidráulico para Labranza de Conservación 5 discos	Baldan	80	5.5	Franco	\N	618	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-10.webp	5	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
18	Sembradora de Precisión Autotransportable 7200	Baldan	255	7.2	Franco	\N	13660	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-agiflex-sembradora-de-precision-autotransportable-1.webp	\N	https://baldan.com.br/es/productos/agiflex-sembradora-de-precision-autotransportable/
19	Sembradora de Precisión Autotransportable 8100	Baldan	270	8.1	Franco	\N	13660	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-agiflex-sembradora-de-precision-autotransportable-2.webp	\N	https://baldan.com.br/es/productos/agiflex-sembradora-de-precision-autotransportable/
20	Sembradora de Precisión Autotransportable 9000	Baldan	295	9	Franco	\N	13660	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-agiflex-sembradora-de-precision-autotransportable-3.webp	\N	https://baldan.com.br/es/productos/agiflex-sembradora-de-precision-autotransportable/
21	Arado Reversible Hidráulico ARH (L)	Baldan	90	0.9	Franco	\N	734	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-arh-arado-reversible-hidraulico-2.webp	4	https://baldan.com.br/es/productos/arh-arado-reversible-hidraulico/
22	Arado Reversible Hidráulico ARH (P)	Baldan	130	1.2	Franco	\N	1083	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-arh-arado-reversible-hidraulico-5.webp	5	https://baldan.com.br/es/productos/arh-arado-reversible-hidraulico/
23	Arado Subsolador con Desarme Automático ASDAH	Baldan	202.5	3.375	Franco	450	1800	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-arado-subsolador-con-desarme-y-rearme-automatico-3.webp	\N	https://baldan.com.br/es/productos/asda-arado-subsolador-con-desarme-y-rearme-automatico/
24	Arado Subsolador con Desarme Automático ASDACR	Baldan	292.5	4.875	Franco	450	3000	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-arado-subsolador-con-desarme-y-rearme-automatico-8.webp	\N	https://baldan.com.br/es/productos/asda-arado-subsolador-con-desarme-y-rearme-automatico/
32	Arado Subsolador Tubular Hidráulico ASTH 3/3	Baldan	42.5	0.74	Franco	\N	330	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-1.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
95	Cultivador Abonador Hidráulico 3300	Baldan	54	3.3	Franco	\N	325	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ctv-n-cultivador-abonador-hidraulico-3.webp	\N	https://baldan.com.br/es/productos/ctv-n-cultivador-abonador-hidraulico/
117	Rastra Hidráulica Off-Set 20 discos	Baldan	75	2.061	Franco	\N	748	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-5.webp	20	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
118	Rastra Hidráulica Off-Set 22 discos	Baldan	80	2.29	Franco	\N	789	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-6.webp	22	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
119	Rastra Aradora de Arrastre GR	Baldan	144.5	3.2	Franco	\N	1910	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gr-grp-rastra-aradora-de-arrastre-8.webp	28	https://baldan.com.br/es/productos/gr-grp-rastra-aradora-de-arrastre/
120	Rastra Aradora de Arrastre GRP	Baldan	123.5	2.7	Franco	\N	1755	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gr-grp-rastra-aradora-de-arrastre-14.webp	24	https://baldan.com.br/es/productos/gr-grp-rastra-aradora-de-arrastre/
190	Rastra Niveladora de Control Remoto Tándem 108 discos	Baldan	405	10.253	Franco	168	10000	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-movere-rastra-niveladora-de-control-remoto-tandem-1.webp	108	https://baldan.com.br/es/productos/movere-rastra-niveladora-de-control-remoto-tandem/
191	Rastra Niveladora de Control Remoto Tándem 124 discos	Baldan	463	11.815	Franco	168	12270	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-movere-rastra-niveladora-de-control-remoto-tandem-2.webp	124	https://baldan.com.br/es/productos/movere-rastra-niveladora-de-control-remoto-tandem/
192	Rastra Niveladora NV	Baldan	160.5	5.5	Franco	\N	1582	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nv-rastra-niveladora-18.webp	56	https://baldan.com.br/es/productos/nv-rastra-niveladora/
194	Rastra Niveladora Control Remoto NVAP	Baldan	147.5	4.81	Franco	\N	2200	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvam-nvap-rastra-niveladora-control-remoto-19.webp	56	https://baldan.com.br/es/productos/nvam-nvap-rastra-niveladora-control-remoto/
211	Rastra Niveladora Flotante NVF / NVFP	Baldan	194	7.1	Franco	\N	2170	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvfnvf-p-rastra-niveladora-flotante-9.webp	72	https://baldan.com.br/es/productos/nvfnvf-p-rastra-niveladora-flotante/
212	Rastra Niveladora Flotante NVF TANDEM	Baldan	287.5	11.8	Franco	\N	4365	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvfnvf-p-rastra-niveladora-flotante-12.webp	120	https://baldan.com.br/es/productos/nvfnvf-p-rastra-niveladora-flotante/
231	Sembradora de Precisión PP SOLO 4000	Baldan	95	3.15	Franco	\N	4131	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-1.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
261	Sembradora de Precisión Pantográfica 4950	Baldan	125	4.95	Franco	\N	5610	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sembradora-de-precision-pantografica-1.webp	\N	https://baldan.com.br/es/productos/sembradora-de-precision-pantografica/
262	Sembradora de Precisión Pantográfica 5850	Baldan	147.5	5.85	Franco	\N	5610	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sembradora-de-precision-pantografica-2.webp	\N	https://baldan.com.br/es/productos/sembradora-de-precision-pantografica/
263	Sembradora de Precisión Pantográfica 6750	Baldan	167.5	6.75	Franco	\N	5610	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sembradora-de-precision-pantografica-3.webp	\N	https://baldan.com.br/es/productos/sembradora-de-precision-pantografica/
264	Sembradora de Precisión 5000	Baldan	137.5	4.08	Franco	\N	3200	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-skadi-sembradora-de-precision-1.webp	\N	https://baldan.com.br/es/productos/skadi-sembradora-de-precision/
265	Sembradora de Precisión 6000	Baldan	162.5	4.76	Franco	\N	5000	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-skadi-sembradora-de-precision-2.webp	\N	https://baldan.com.br/es/productos/skadi-sembradora-de-precision/
266	Sembradora de Precisión 7000	Baldan	182.5	5.44	Franco	\N	5000	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-skadi-sembradora-de-precision-3.webp	\N	https://baldan.com.br/es/productos/skadi-sembradora-de-precision/
267	Surcador para Caña de Azúcar 930	Baldan	67.5	0.93	Franco	\N	190	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sls-surcador-para-cana-de-azucar-1.webp	\N	https://baldan.com.br/es/productos/sls-surcador-para-cana-de-azucar/
268	Surcador para Caña de Azúcar 2100	Baldan	87.5	2.1	Franco	\N	400	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sls-surcador-para-cana-de-azucar-2.webp	\N	https://baldan.com.br/es/productos/sls-surcador-para-cana-de-azucar/
269	Surcador para Caña de Azúcar 3530	Baldan	106	3.53	Franco	\N	500	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sls-surcador-para-cana-de-azucar-3.webp	\N	https://baldan.com.br/es/productos/sls-surcador-para-cana-de-azucar/
281	Rastra Desterronadora y Niveladora 42 discos	Baldan	100	3.6	Franco	\N	810	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-6.webp	42	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
276	Rastra Desterronadora y Niveladora 20 discos	Baldan	53	1.9	Franco	\N	530	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-7.webp	20	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
277	Rastra Desterronadora y Niveladora 24 discos	Baldan	63	2.3	Franco	\N	587	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-8.webp	24	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
278	Rastra Desterronadora y Niveladora 28 discos	Baldan	72.5	2.7	Franco	\N	682	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-9.webp	28	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
279	Rastra Desterronadora y Niveladora 32 discos	Baldan	82.5	3.1	Franco	\N	760	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-10.webp	32	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
280	Rastra Desterronadora y Niveladora 36 discos	Baldan	95	3.5	Franco	\N	842	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-11.webp	36	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora/
287	Sembradora de Precisión 9500	Baldan	215	9	Franco	\N	11190	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-topografic-sembradora-de-precision-6.webp	\N	https://baldan.com.br/es/productos/sp-topografic-sembradora-de-precision/
288	Sembradora Siembra Directa Especial SPDE CXP 3000	Baldan	85	2.55	Franco	\N	3431	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-spde-sembradora-siembra-directa-especial-1.webp	\N	https://baldan.com.br/es/productos/spde-sembradora-siembra-directa-especial/
289	Sembradora Siembra Directa Especial SPDE CXP 4000	Baldan	102.5	3.23	Franco	\N	3830	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-spde-sembradora-siembra-directa-especial-2.webp	\N	https://baldan.com.br/es/productos/spde-sembradora-siembra-directa-especial/
290	Sembradora Siembra Directa Especial SPDE CXP 5000	Baldan	122.5	3.91	Franco	\N	4250	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-spde-sembradora-siembra-directa-especial-3.webp	\N	https://baldan.com.br/es/productos/spde-sembradora-siembra-directa-especial/
12	Abonador Hidráulico para Labranza de Conservación 12 discos	Baldan	88	5.5	Franco	\N	933	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-23.webp	12	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
13	Abonador Hidráulico para Labranza de Conservación 14 discos	Baldan	95.5	5.5	Franco	\N	1043	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-24.webp	14	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
9	Abonador Hidráulico para Labranza de Conservación 6 discos	Baldan	80	5.5	Franco	\N	653	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-17.webp	6	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
10	Abonador Hidráulico para Labranza de Conservación 8 discos	Baldan	88	3.65	Franco	\N	660	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-19.webp	8	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
11	Abonador Hidráulico para Labranza de Conservación 10 discos	Baldan	88	5.5	Franco	\N	855	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-acd-n-abonador-hidraulico-para-labranza-de-conservacion-21.webp	10	https://baldan.com.br/es/productos/acd-n-abonador-hidraulico-para-labranza-de-conservacion/
14	Arado Fijo 2 discos	Baldan	45	0.6	Franco	\N	308	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-af-arado-fijo-1.webp	2	https://baldan.com.br/es/productos/af-arado-fijo/
15	Arado Fijo 3 discos	Baldan	55	0.9	Franco	\N	387	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-af-arado-fijo-2.webp	3	https://baldan.com.br/es/productos/af-arado-fijo/
16	Arado Fijo 4 discos	Baldan	82.5	1.2	Franco	\N	515	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-af-arado-fijo-3.webp	4	https://baldan.com.br/es/productos/af-arado-fijo/
17	Arado Fijo 5 discos	Baldan	110	1.5	Franco	\N	569	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-af-arado-fijo-4.webp	5	https://baldan.com.br/es/productos/af-arado-fijo/
25	Arado Subsolador con Desarme Automático ASDADR	Baldan	292.5	4.875	Franco	450	4200	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-arado-subsolador-con-desarme-y-rearme-automatico-13.webp	13	https://baldan.com.br/es/productos/asda-arado-subsolador-con-desarme-y-rearme-automatico/
26	Arado Subsolador con Desarme Automático – Resorte Plano ASDAH-MP	Baldan	202.5	3.375	Franco	\N	1800	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano-3.webp	\N	https://baldan.com.br/es/productos/asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano/
27	Arado Subsolador con Desarme Automático – Resorte Plano ASDACR-MP	Baldan	292.5	4.875	Franco	\N	3000	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano-8.webp	\N	https://baldan.com.br/es/productos/asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano/
28	Arado Subsolador con Desarme Automático – Resorte Plano ASDADR-MP	Baldan	292.5	4.875	Franco	\N	4200	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano-13.webp	13	https://baldan.com.br/es/productos/asda-mp-arado-subsolador-con-desarme-y-rearme-automatico-resorte-plano/
29	Arado Subsolador con Desarme Automático 5	Baldan	120	1.875	Franco	\N	1944	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico-4.webp	\N	https://baldan.com.br/es/productos/asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico/
30	Arado Subsolador con Desarme Automático 7	Baldan	140	2.625	Franco	\N	2542	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico-5.webp	\N	https://baldan.com.br/es/productos/asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico/
31	Arado Subsolador con Desarme Automático 9	Baldan	180	3.375	Franco	\N	3005	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico-6.webp	\N	https://baldan.com.br/es/productos/asda-multi-nuevo-arado-subsolador-con-desarme-y-rearme-automatico/
33	Arado Subsolador Tubular Hidráulico ASTH 5/3	Baldan	42.5	1.32	Franco	\N	358	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-2.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
34	Arado Subsolador Tubular Hidráulico ASTH 5/5	Baldan	57.5	1.32	Franco	\N	425	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-3.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
35	Arado Subsolador Tubular Hidráulico ASTH 7/5	Baldan	60.5	1.52	Franco	\N	479	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-4.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
36	Arado Subsolador Tubular Hidráulico ASTH 7/7	Baldan	75	1.86	Franco	\N	545	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-5.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
37	Arado Subsolador Tubular Hidráulico ASTH 9/5	Baldan	57.5	2.48	Franco	\N	513	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-6.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
38	Arado Subsolador Tubular Hidráulico ASTH 9/7	Baldan	75	2.1	Franco	\N	579	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-7.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
39	Arado Subsolador Tubular Hidráulico ASTH 9/9	Baldan	97.5	2.48	Franco	\N	645	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-8.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
40	Arado Subsolador Tubular Hidráulico ASTH 11/9	Baldan	97.5	3.04	Franco	\N	680	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-9.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
41	Arado Subsolador Tubular Hidráulico ASTH 11/11	Baldan	115	3	Franco	\N	745	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-asth-arado-subsolador-tubular-hidraulico-2-10.webp	\N	https://baldan.com.br/es/productos/asth-arado-subsolador-tubular-hidraulico-2/
42	Rastra Offset Control Remoto 48 discos	Baldan	322.5	6.23	Franco	\N	7300	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-4860-discos-rastra-offset-control-remoto-1.webp	48	https://baldan.com.br/es/productos/cri-4860-discos-rastra-offset-control-remoto/
43	Rastra Offset Control Remoto 52 discos	Baldan	350	6.745	Franco	\N	7720	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-4860-discos-rastra-offset-control-remoto-2.webp	52	https://baldan.com.br/es/productos/cri-4860-discos-rastra-offset-control-remoto/
44	Rastra Offset Control Remoto 56 discos	Baldan	372.5	7.235	Franco	\N	7910	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-4860-discos-rastra-offset-control-remoto-3.webp	56	https://baldan.com.br/es/productos/cri-4860-discos-rastra-offset-control-remoto/
45	Rastra Offset Control Remoto 60 discos	Baldan	402.5	7.745	Franco	\N	8270	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-4860-discos-rastra-offset-control-remoto-4.webp	60	https://baldan.com.br/es/productos/cri-4860-discos-rastra-offset-control-remoto/
46	Rastra Aradora Intermediaria Control Remoto Plegable 40 discos	Baldan	250	5.29	Franco	\N	5461	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-a-rastra-aradora-intermediaria-control-remoto-plegable-1.webp	40	https://baldan.com.br/es/productos/cri-a-rastra-aradora-intermediaria-control-remoto-plegable/
47	Rastra Aradora Intermediaria Control Remoto Plegable 44 discos	Baldan	272	5.84	Franco	\N	5623	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-a-rastra-aradora-intermediaria-control-remoto-plegable-2.webp	44	https://baldan.com.br/es/productos/cri-a-rastra-aradora-intermediaria-control-remoto-plegable/
49	Rastra Aradora Intermediaria Control Remoto Especial 36 discos	Baldan	220	4.826	Franco	\N	4652	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-e-rastra-aradora-intermediaria-control-remoto-especial-1.webp	36	https://baldan.com.br/es/productos/cri-e-rastra-aradora-intermediaria-control-remoto-especial/
50	Rastra Aradora Intermediaria Control Remoto Especial 40 discos	Baldan	250	5.36	Franco	\N	4883	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-e-rastra-aradora-intermediaria-control-remoto-especial-2.webp	40	https://baldan.com.br/es/productos/cri-e-rastra-aradora-intermediaria-control-remoto-especial/
51	Rastra Aradora Intermediaria Control Remoto Especial 44 discos	Baldan	272	5.896	Franco	\N	5115	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-e-rastra-aradora-intermediaria-control-remoto-especial-3.webp	44	https://baldan.com.br/es/productos/cri-e-rastra-aradora-intermediaria-control-remoto-especial/
52	Rastra Aradora Intermediaria Control Remoto Especial 48 discos	Baldan	295.5	6.432	Franco	\N	5345	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-e-rastra-aradora-intermediaria-control-remoto-especial-4.webp	48	https://baldan.com.br/es/productos/cri-e-rastra-aradora-intermediaria-control-remoto-especial/
53	Rastra Off-Set Control Remoto Semi Pesada 12 discos	Baldan	90.5	1.65	Franco	\N	1730	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-1.webp	12	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
54	Rastra Off-Set Control Remoto Semi Pesada 14 discos	Baldan	103.5	1.95	Franco	\N	1840	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-2.webp	14	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
55	Rastra Off-Set Control Remoto Semi Pesada 16 discos	Baldan	121	2.25	Franco	\N	2240	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-3.webp	16	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
56	Rastra Off-Set Control Remoto Semi Pesada 18 discos	Baldan	134.5	2.55	Franco	\N	2460	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-4.webp	18	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
57	Rastra Off-Set Control Remoto Semi Pesada 20 discos	Baldan	147.5	2.85	Franco	\N	2847	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-5.webp	20	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
58	Rastra Off-Set Control Remoto Semi Pesada 22 discos	Baldan	163	3.15	Franco	\N	2965	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-6.webp	22	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
59	Rastra Off-Set Control Remoto Semi Pesada 24 discos	Baldan	176	3.45	Franco	\N	3090	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-7.webp	24	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
60	Rastra Off-Set Control Remoto Semi Pesada 26 discos	Baldan	194	3.75	Franco	\N	3200	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-r-rastra-off-set-control-remoto-semi-pesada-8.webp	26	https://baldan.com.br/es/productos/cri-r-rastra-off-set-control-remoto-semi-pesada/
61	Rastra Aradora Intermediaria Control Remoto 12 discos	Baldan	73.5	1.5	Franco	\N	1339	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-1.webp	12	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
62	Rastra Aradora Intermediaria Control Remoto 14 discos	Baldan	85.5	1.75	Franco	\N	1405	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-2.webp	14	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
63	Rastra Aradora Intermediaria Control Remoto 16 discos	Baldan	97.5	2	Franco	\N	1780	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-3.webp	16	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
64	Rastra Aradora Intermediaria Control Remoto 18 discos	Baldan	110	2.3	Franco	\N	1920	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-4.webp	18	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
65	Rastra Aradora Intermediaria Control Remoto 20 discos	Baldan	122	2.55	Franco	\N	2012	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-5.webp	20	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
66	Rastra Aradora Intermediaria Control Remoto 22 discos	Baldan	134	2.835	Franco	\N	2103	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-6.webp	22	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
67	Rastra Aradora Intermediaria Control Remoto 24 discos	Baldan	146.5	3.1	Franco	\N	2209	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-7.webp	24	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
68	Rastra Aradora Intermediaria Control Remoto 26 discos	Baldan	159.5	3.35	Franco	\N	2311	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-8.webp	26	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
69	Rastra Aradora Intermediaria Control Remoto 28 discos	Baldan	171	3.65	Franco	\N	2383	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-9.webp	28	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
70	Rastra Aradora Intermediaria Control Remoto 30 discos	Baldan	183	3.925	Franco	\N	2453	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-10.webp	30	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
71	Rastra Aradora Intermediaria Control Remoto 32 discos	Baldan	195.5	4.2	Franco	\N	3689	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-11.webp	32	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
72	Rastra Aradora Intermediaria Control Remoto 36 discos	Baldan	220	4.7	Franco	\N	4172	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-12.webp	36	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
73	Rastra Aradora Intermediaria Control Remoto 40 discos	Baldan	244	5.25	Franco	\N	4499	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-13.webp	40	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
74	Rastra Aradora Intermediaria Control Remoto 44 discos	Baldan	269	5.8	Franco	\N	4719	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cri-rastra-aradora-intermediaria-control-remoto-14.webp	44	https://baldan.com.br/es/productos/cri-rastra-aradora-intermediaria-control-remoto/
75	Rastra Aradora Control Remoto Leve 18 discos	Baldan	85	2	Franco	\N	1170	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-2.webp	18	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
76	Rastra Aradora Control Remoto Leve 20 discos	Baldan	95	2.25	Franco	\N	1320	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-3.webp	20	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
77	Rastra Aradora Control Remoto Leve 22 discos	Baldan	105	2.42	Franco	\N	1430	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-4.webp	22	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
78	Rastra Aradora Control Remoto Leve 24 discos	Baldan	115	2.7	Franco	\N	1550	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-5.webp	24	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
79	Rastra Aradora Control Remoto Leve 28 discos	Baldan	122.5	3.2	Franco	\N	1984	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-6.webp	28	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
80	Rastra Aradora Control Remoto Leve 32 discos	Baldan	145	3.65	Franco	\N	2100	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-l-rastra-aradora-control-remoto-leve-7.webp	32	https://baldan.com.br/es/productos/crsg-l-rastra-aradora-control-remoto-leve/
81	Rastra Aradora Control Remoto 12 discos	Baldan	66.5	1.3	Franco	\N	1276	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-2.webp	12	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
82	Rastra Aradora Control Remoto 14 discos	Baldan	77	1.15	Franco	\N	1331	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-3.webp	14	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
83	Rastra Aradora Control Remoto 16 discos	Baldan	90	1.75	Franco	\N	1401	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-4.webp	16	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
84	Rastra Aradora Control Remoto 18 discos	Baldan	100	2	Franco	\N	1793	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-5.webp	18	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
85	Rastra Aradora Control Remoto 20 discos	Baldan	112	2.25	Franco	\N	1904	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-6.webp	20	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
86	Rastra Aradora Control Remoto 22 discos	Baldan	132.5	2.42	Franco	\N	1975	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-7.webp	22	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
87	Rastra Aradora Control Remoto 24 discos	Baldan	138.5	2.7	Franco	\N	2037	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-8.webp	24	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
88	Rastra Aradora Control Remoto 28 discos	Baldan	155.5	3.22	Franco	\N	2190	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-crsg-rastra-aradora-control-remoto-9.webp	28	https://baldan.com.br/es/productos/crsg-rastra-aradora-control-remoto/
89	Cultivador Tipo Rastra 6 discos	Baldan	45	1.3	Franco	\N	250	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ctgb-cultivador-tipo-rastra-1.webp	6	https://baldan.com.br/es/productos/ctgb-cultivador-tipo-rastra/
90	Cultivador Tipo Rastra 8 discos	Baldan	45	1.4	Franco	\N	280	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ctgb-cultivador-tipo-rastra-2.webp	8	https://baldan.com.br/es/productos/ctgb-cultivador-tipo-rastra/
91	Cultivador Tipo Rastra 12 discos	Baldan	58	1.3	Franco	\N	505	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ctgb-cultivador-tipo-rastra-3.webp	12	https://baldan.com.br/es/productos/ctgb-cultivador-tipo-rastra/
92	Cultivador Tipo Rastra 16 discos	Baldan	58	1.4	Franco	\N	550	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ctgb-cultivador-tipo-rastra-4.webp	16	https://baldan.com.br/es/productos/ctgb-cultivador-tipo-rastra/
93	Cultivador Abonador Hidráulico 2250	Baldan	45.5	2.25	Franco	\N	300	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-1.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
101	Cultivador Abonador Hidráulico 2900	Baldan	54	2.9	Franco	\N	355	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-2.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
94	Cultivador Abonador Hidráulico 2900 / 3300	Baldan	58.5	2.9	Franco	\N	380	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-3.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
96	Cultivador Abonador Hidráulico 3300 / 3650	Baldan	63	3.3	Franco	\N	458	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-5.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
97	Cultivador Abonador Hidráulico 3650 / 4200	Baldan	75	3.65	Franco	\N	493	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-6.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
98	Cultivador Abonador Hidráulico 4200	Baldan	80.5	4.2	Franco	\N	558	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-7.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
99	Cultivador Abonador Hidráulico 4500	Baldan	80.5	4.5	Franco	\N	605	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-8.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
100	Cultivador Abonador Hidráulico 5500	Baldan	80.5	5.5	Franco	\N	635	abonador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-cvac-n-cultivador-abonador-hidraulico-9.webp	\N	https://baldan.com.br/es/productos/cvac-n-cultivador-abonador-hidraulico/
102	Distribuidor de Calcáreo y Abono Transmisión por Correas DCF-C 3000	Baldan	60	1.76	Franco	\N	850	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas-1.webp	\N	https://baldan.com.br/es/productos/dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas/
103	Distribuidor de Calcáreo y Abono Transmisión por Correas DCF-C 6000	Baldan	82.5	1.886	Franco	\N	1203	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas-2.webp	\N	https://baldan.com.br/es/productos/dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas/
104	Distribuidor de Calcáreo y Abono Transmisión por Correas DCF-C 8000	Baldan	95	1.886	Franco	\N	1325	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas-3.webp	\N	https://baldan.com.br/es/productos/dcf-c-distribuidor-de-calcareo-y-abono-transmision-por-correas/
105	Distribuidor de Calcáreo, Fertilizante y Abono Orgánico. DCF-CO 3000	Baldan	60	1.7	Franco	\N	1070	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico-1.webp	\N	https://baldan.com.br/es/productos/dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico/
106	Distribuidor de Calcáreo, Fertilizante y Abono Orgánico. DCF-CO 6000	Baldan	82.5	1.8	Franco	\N	1390	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico-2.webp	\N	https://baldan.com.br/es/productos/dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico/
107	Distribuidor de Calcáreo, Fertilizante y Abono Orgánico. DCF-CO 8000	Baldan	95	1.9	Franco	\N	1480	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico-3.webp	\N	https://baldan.com.br/es/productos/dcf-co-distribuidor-de-calcareo-fertilizante-y-abono-organico/
110	Rastra de Control Remoto Súper Intermedia Tándem 66 discos	Baldan	327.5	9.04	Franco	\N	9010	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gcrti-rastra-control-remoto-tandem-intermediaria-1.webp	66	https://baldan.com.br/es/productos/gcrti-rastra-control-remoto-tandem-intermediaria/
111	Rastra de Control Remoto Súper Intermedia Tándem 70 discos	Baldan	317.5	9.6	Franco	\N	9174	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gcrti-rastra-control-remoto-tandem-intermediaria-2.webp	70	https://baldan.com.br/es/productos/gcrti-rastra-control-remoto-tandem-intermediaria/
112	Rastra Aradora Doble Offset Baldan	Baldan	517.5	12.319	Franco	\N	13720	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gdob-rastra-aradora-doble-off-set-baldan-1.webp	90	https://baldan.com.br/es/productos/gdob-rastra-aradora-doble-off-set-baldan/
113	Rastra Hidráulica Off-Set 12 discos	Baldan	45.5	1.145	Franco	\N	535	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-1.webp	12	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
114	Rastra Hidráulica Off-Set 14 discos	Baldan	45.5	1.374	Franco	\N	586	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-2.webp	14	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
115	Rastra Hidráulica Off-Set 16 discos	Baldan	60.5	1.603	Franco	\N	627	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-3.webp	16	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
116	Rastra Hidráulica Off-Set 18 discos	Baldan	70.5	1.832	Franco	\N	687	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-ghogho-r-rastra-hidraulica-off-set-4.webp	18	https://baldan.com.br/es/productos/ghogho-r-rastra-hidraulica-off-set/
123	Rastra Reversible Hidráulica GRH	Baldan	58	1.4	Franco	\N	523	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-grh-rastra-reversible-hidraulica-4.webp	16	https://baldan.com.br/es/productos/grh-rastra-reversible-hidraulica/
124	Rastra Reversible Hidráulica GRHR	Baldan	58	1.4	Franco	\N	656	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-grh-rastra-reversible-hidraulica-8.webp	16	https://baldan.com.br/es/productos/grh-rastra-reversible-hidraulica/
125	Rastra Aradora Super Pesada de Arrastre 10 discos	Baldan	120	1.9	Franco	\N	2680	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-1.webp	10	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
126	Rastra Aradora Super Pesada de Arrastre 12 discos	Baldan	140.5	2.35	Franco	\N	2912	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-2.webp	12	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
127	Rastra Aradora Super Pesada de Arrastre 14 discos	Baldan	163.5	2.8	Franco	\N	3330	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-3.webp	14	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
128	Rastra Aradora Super Pesada de Arrastre 16 discos	Baldan	189	3.2	Franco	\N	3760	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-4.webp	16	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
129	Rastra Aradora Super Pesada de Arrastre 18 discos	Baldan	212.5	3.65	Franco	\N	3991	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-5.webp	18	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
130	Rastra Aradora Super Pesada de Arrastre 20 discos	Baldan	240	4.1	Franco	\N	4324	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspa-rastra-aradora-super-pesada-de-arrastre-6.webp	20	https://baldan.com.br/es/productos/gspa-rastra-aradora-super-pesada-de-arrastre/
131	Rastra Aradora Offset Control Remoto – Super Pesada Especial 12 discos	Baldan	295	2.957	Franco	\N	5318	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-1.webp	12	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
132	Rastra Aradora Offset Control Remoto – Super Pesada Especial 14 discos	Baldan	295	3.405	Franco	\N	5866	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-2.webp	14	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
133	Rastra Aradora Offset Control Remoto – Super Pesada Especial 16 discos	Baldan	380	3.909	Franco	\N	7301	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-3.webp	16	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
134	Rastra Aradora Offset Control Remoto – Super Pesada Especial 18 discos	Baldan	415	4.371	Franco	\N	7763	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-4.webp	18	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
135	Rastra Aradora Offset Control Remoto – Super Pesada Especial 20 discos	Baldan	445	4.828	Franco	\N	8099	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-5.webp	20	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
136	Rastra Aradora Offset Control Remoto – Super Pesada Especial 22 discos	Baldan	480	5.292	Franco	\N	8428	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-6.webp	22	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
137	Rastra Aradora Offset Control Remoto – Super Pesada Especial 24 discos	Baldan	525	5.759	Franco	\N	8750	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada-7.webp	24	https://baldan.com.br/es/productos/gspcr-1224-discos-rastra-aradora-offset-control-remoto-super-pesada/
138	Rastra Aradora Offset Control Remoto – Super Pesada 28 discos	Baldan	434	5.605	Franco	\N	8070	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada-1.webp	28	https://baldan.com.br/es/productos/gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada/
139	Rastra Aradora Offset Control Remoto – Super Pesada 32 discos	Baldan	496	6.377	Franco	\N	9540	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada-2.webp	32	https://baldan.com.br/es/productos/gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada/
140	Rastra Aradora Offset Control Remoto – Super Pesada 36 discos	Baldan	558	7.147	Franco	\N	10030	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada-3.webp	36	https://baldan.com.br/es/productos/gspcr-2836-discos-rastra-aradora-offset-control-remoto-pesada/
141	Rastra Aradora Offset Control Remoto – Super Pesada 10 discos	Baldan	155	2.06	Franco	\N	3638	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-1.webp	10	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
142	Rastra Aradora Offset Control Remoto – Super Pesada 12 discos	Baldan	186	2.55	Franco	\N	3857	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-2.webp	12	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
143	Rastra Aradora Offset Control Remoto – Super Pesada 14 discos	Baldan	217	3.04	Franco	\N	4485	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-3.webp	14	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
144	Rastra Aradora Offset Control Remoto – Super Pesada 16 discos	Baldan	248	3.48	Franco	\N	4950	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-4.webp	16	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
145	Rastra Aradora Offset Control Remoto – Super Pesada 18 discos	Baldan	279	3.97	Franco	\N	4991	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-5.webp	18	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
146	Rastra Aradora Offset Control Remoto – Super Pesada 20 discos	Baldan	310	4.46	Franco	\N	5500	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-6.webp	20	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
147	Rastra Aradora Offset Control Remoto – Super Pesada 22 discos	Baldan	341	4.9	Franco	\N	6032	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-7.webp	22	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
148	Rastra Aradora Offset Control Remoto – Super Pesada 24 discos	Baldan	372	5.34	Franco	\N	6331	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gspcr-rastra-aradora-super-pesada-control-remoto-8.webp	24	https://baldan.com.br/es/productos/gspcr-rastra-aradora-super-pesada-control-remoto/
149	Rastra Aradora Pesada de Arrastre 10 discos	Baldan	95	1.53	Franco	\N	1655	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-1.webp	10	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
150	Rastra Aradora Pesada de Arrastre 12 discos	Baldan	114	1.87	Franco	\N	1835	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-2.webp	12	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
151	Rastra Aradora Pesada de Arrastre 14 discos	Baldan	133	2.39	Franco	\N	2007	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-3.webp	14	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
152	Rastra Aradora Pesada de Arrastre 16 discos	Baldan	152	2.25	Franco	\N	2253	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-4.webp	16	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
153	Rastra Aradora Pesada de Arrastre 18 discos	Baldan	171	2.89	Franco	\N	2547	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-5.webp	18	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
154	Rastra Aradora Pesada de Arrastre 20 discos	Baldan	190	3.23	Franco	\N	2753	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gta-rastra-aradora-pesada-de-arrastre-6.webp	20	https://baldan.com.br/es/productos/gta-rastra-aradora-pesada-de-arrastre/
155	Rastra Aradora Offset Control Remoto (Pesada) 34 discos	Baldan	374	5.16	Franco	\N	7710	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada-1.webp	34	https://baldan.com.br/es/productos/gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada/
156	Rastra Aradora Offset Control Remoto (Pesada) 36 discos	Baldan	396	5.783	Franco	\N	7915	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada-2.webp	36	https://baldan.com.br/es/productos/gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada/
157	Rastra Aradora Offset Control Remoto (Pesada) 40 discos	Baldan	440	6.402	Franco	\N	8570	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada-3.webp	40	https://baldan.com.br/es/productos/gtcr-3440-discos-rastra-aradora-offset-control-remoto-pesada/
158	Rastra Control Remoto Cañera 16 discos	Baldan	120	2.4	Franco	\N	2521	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-c-rastra-control-remoto-canera-1.webp	16	https://baldan.com.br/es/productos/gtcr-c-rastra-control-remoto-canera/
159	Rastra Control Remoto Cañera 18 discos	Baldan	135	2.7	Franco	\N	2758	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-c-rastra-control-remoto-canera-2.webp	18	https://baldan.com.br/es/productos/gtcr-c-rastra-control-remoto-canera/
160	Rastra Control Remoto Cañera 20 discos	Baldan	150	3	Franco	\N	2894	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-c-rastra-control-remoto-canera-3.webp	20	https://baldan.com.br/es/productos/gtcr-c-rastra-control-remoto-canera/
161	Rastra Control Remoto Cañera 22 discos	Baldan	165	3.3	Franco	\N	3029	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-c-rastra-control-remoto-canera-4.webp	22	https://baldan.com.br/es/productos/gtcr-c-rastra-control-remoto-canera/
162	Rastra Control Remoto Cañera 24 discos	Baldan	180	3.6	Franco	\N	3166	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-c-rastra-control-remoto-canera-5.webp	24	https://baldan.com.br/es/productos/gtcr-c-rastra-control-remoto-canera/
163	Rastra Aradora Offset Control Remoto – Pesada 16 discos	Baldan	184	2.7	Franco	\N	3680	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee-1.webp	16	https://baldan.com.br/es/productos/gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee/
164	Rastra Aradora Offset Control Remoto – Pesada 18 discos	Baldan	207	3.06	Franco	\N	3980	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee-2.webp	18	https://baldan.com.br/es/productos/gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee/
165	Rastra Aradora Offset Control Remoto – Pesada 20 discos	Baldan	230	3.42	Franco	\N	4180	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee-3.webp	20	https://baldan.com.br/es/productos/gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee/
166	Rastra Aradora Offset Control Remoto – Pesada 22 discos	Baldan	253	3.78	Franco	\N	4390	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee-4.webp	22	https://baldan.com.br/es/productos/gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee/
167	Rastra Aradora Offset Control Remoto – Pesada 24 discos	Baldan	276	4.14	Franco	\N	4630	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee-5.webp	24	https://baldan.com.br/es/productos/gtcr-cr-rastra-aradora-offset-control-remoto-pesada-c4tnee/
168	Rastra Aradora Offset Control Remoto (Pesada) 10 discos	Baldan	110	1.53	Franco	\N	1875	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-1.webp	10	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
169	Rastra Aradora Offset Control Remoto (Pesada) 12 discos	Baldan	132	1.87	Franco	\N	2493	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-2.webp	12	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
170	Rastra Aradora Offset Control Remoto (Pesada) 14 discos	Baldan	154	2.39	Franco	\N	2632	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-3.webp	14	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
171	Rastra Aradora Offset Control Remoto (Pesada) 16 discos	Baldan	176	2.55	Franco	\N	2886	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-4.webp	16	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
172	Rastra Aradora Offset Control Remoto (Pesada) 18 discos	Baldan	198	2.89	Franco	\N	3542	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-5.webp	18	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
173	Rastra Aradora Offset Control Remoto (Pesada) 20 discos	Baldan	220	3.23	Franco	\N	3833	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-6.webp	20	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
174	Rastra Aradora Offset Control Remoto (Pesada) 22 discos	Baldan	242	3.57	Franco	\N	4107	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-7.webp	22	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
175	Rastra Aradora Offset Control Remoto (Pesada) 24 discos	Baldan	264	3.91	Franco	\N	4357	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-8.webp	24	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
176	Rastra Aradora Offset Control Remoto (Pesada) 30 discos	Baldan	330	4.93	Franco	\N	4798	plow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtcr-rastra-aradora-pesada-control-remoto-9.webp	30	https://baldan.com.br/es/productos/gtcr-rastra-aradora-pesada-control-remoto/
177	Grua Trasera	Baldan	70	2.458	Franco	\N	915	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-gtg-ro-2000-br-grua-trasera-1.webp	\N	https://baldan.com.br/es/productos/gtg-ro-2000-br-grua-trasera/
178	Rastra Hidráulica Tandem 10 discos	Baldan	30	1.8	Franco	\N	184	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-1.webp	10	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
179	Rastra Hidráulica Tandem 16 discos	Baldan	37.5	1.505	Franco	\N	294	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-2.webp	16	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
180	Rastra Hidráulica Tandem 20 discos	Baldan	46	1.875	Franco	\N	328	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-3.webp	20	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
181	Rastra Hidráulica Tandem 24 discos	Baldan	56	2.245	Franco	\N	407	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-4.webp	24	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
183	Rastra Hidráulica Tandem 32 discos	Baldan	80	2.985	Franco	\N	599	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-6.webp	32	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
184	Cuchilla Trasera Reversible 1500	Baldan	60	1.5	Franco	\N	233	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-1.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
185	Cuchilla Trasera Reversible 1900	Baldan	65	1.9	Franco	\N	248	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-2.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
186	Cuchilla Trasera Reversible 2100	Baldan	65	2.1	Franco	\N	310	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-3.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
187	Cuchilla Trasera Reversible 2200	Baldan	85	2.2	Franco	\N	264	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-4.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
188	Cuchilla Trasera Reversible 2300	Baldan	85	2.3	Franco	\N	272	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-5.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
189	Cuchilla Trasera Reversible 2400	Baldan	85	2.4	Franco	\N	325	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-lt-cuchilla-trasera-reversible-6.webp	\N	https://baldan.com.br/es/productos/lt-cuchilla-trasera-reversible/
182	Rastra Hidráulica Tandem 28 discos	Baldan	68	2.615	Franco	\N	184	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-hi-rastra-hidraulica-tandem-5.webp	28	https://baldan.com.br/es/productos/hi-rastra-hidraulica-tandem/
193	Rastra Niveladora Control Remoto NVAM	Baldan	150.5	5.1	Franco	\N	1958	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvam-nvap-rastra-niveladora-control-remoto-10.webp	52	https://baldan.com.br/es/productos/nvam-nvap-rastra-niveladora-control-remoto/
195	Rastra Niveladora Control Remoto 28 discos	Baldan	80	2.7	Franco	\N	1243	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-10.webp	28	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
196	Rastra Niveladora Control Remoto 32 discos	Baldan	90	3.1	Franco	\N	1321	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-11.webp	32	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
197	Rastra Niveladora Control Remoto 36 discos	Baldan	102.5	3.5	Franco	\N	1447	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-12.webp	36	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
198	Rastra Niveladora Control Remoto 40 discos	Baldan	112.5	3.9	Franco	\N	1535	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-13.webp	40	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
199	Rastra Niveladora Control Remoto 42 discos	Baldan	117.5	4.1	Franco	\N	1650	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-14.webp	42	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
200	Rastra Niveladora Control Remoto 44 discos	Baldan	130	4.3	Franco	\N	1753	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-15.webp	44	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
201	Rastra Niveladora Control Remoto 48 discos	Baldan	137.5	4.7	Franco	\N	1864	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-16.webp	48	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
202	Rastra Niveladora Control Remoto 52 discos	Baldan	146.5	5.1	Franco	\N	1946	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-17.webp	52	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
203	Rastra Niveladora Control Remoto 56 discos	Baldan	160	5.5	Franco	\N	2074	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvcr-rastra-niveladora-control-remoto-18.webp	56	https://baldan.com.br/es/productos/nvcr-rastra-niveladora-control-remoto/
204	Niveladora Flotante Tubular 48 discos	Baldan	132	4.67	Franco	\N	2403	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-1.webp	48	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
205	Niveladora Flotante Tubular 52 discos	Baldan	143	5.08	Franco	\N	2457	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-2.webp	52	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
206	Niveladora Flotante Tubular 56 discos	Baldan	154	5.5	Franco	\N	2565	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-3.webp	56	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
207	Niveladora Flotante Tubular 60 discos	Baldan	165	5.683	Franco	\N	2649	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-4.webp	60	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
208	Niveladora Flotante Tubular 64 discos	Baldan	176	6.31	Franco	\N	2722	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-5.webp	64	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
209	Niveladora Flotante Tubular 68 discos	Baldan	187	6.71	Franco	\N	2851	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-6.webp	68	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
210	Niveladora Flotante Tubular 72 discos	Baldan	198	7.125	Franco	\N	2936	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-nvf-t-niveladora-flotante-tubular-7.webp	72	https://baldan.com.br/es/productos/nvf-t-niveladora-flotante-tubular/
213	Sembradora de Líneas Baldan 2300	Baldan	58	2.3	Franco	\N	597	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-4.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
216	Sembradora de Líneas Baldan 2800	Baldan	58	2.8	Franco	\N	608	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-5.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
217	Sembradora de Líneas Baldan 3800	Baldan	67.5	3.8	Franco	\N	777	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-9.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
214	Sembradora de Líneas Baldan 3300	Baldan	90	3.3	Franco	\N	1014	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-15.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
215	Sembradora de Líneas Baldan 4300	Baldan	90	4.3	Franco	\N	1082	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-16.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
218	Sembradora de Líneas Baldan 4900	Baldan	90	4.9	Franco	\N	1136	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-air-sembradora-de-lineas-baldan-17.webp	\N	https://baldan.com.br/es/productos/plb-directa-air-sembradora-de-lineas-baldan/
219	Sembradora de Líneas Baldan 1800 | 2800 | 3800	Baldan	45	1.8	Franco	\N	449	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-sembradora-de-lineas-baldan-1.webp	\N	https://baldan.com.br/es/productos/plb-directa-sembradora-de-lineas-baldan/
220	Sembradora de Líneas Baldan 1800 | 2300 | 2800 | 3800	Baldan	58	1.8	Franco	\N	597	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-sembradora-de-lineas-baldan-2.webp	\N	https://baldan.com.br/es/productos/plb-directa-sembradora-de-lineas-baldan/
221	Sembradora de Líneas Baldan 2800 | 3300 | 3800 | 4400	Baldan	67.5	2.8	Franco	\N	766	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-sembradora-de-lineas-baldan-3.webp	\N	https://baldan.com.br/es/productos/plb-directa-sembradora-de-lineas-baldan/
222	Sembradora de Líneas Baldan 2800 | 3800 | 4400	Baldan	90	2.8	Franco	\N	1014	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-plb-directa-sembradora-de-lineas-baldan-5.webp	\N	https://baldan.com.br/es/productos/plb-directa-sembradora-de-lineas-baldan/
223	Pala Niveladora Agrícola de Arrastre PNA 3000	Baldan	90	3	Franco	\N	810	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pna-pala-niveladora-agricola-de-arrastre-1.webp	\N	https://baldan.com.br/es/productos/pna-pala-niveladora-agricola-de-arrastre/
224	Pala Niveladora Agrícola de Arrastre PNA 5000	Baldan	110	4	Franco	\N	1375	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pna-pala-niveladora-agricola-de-arrastre-2.webp	\N	https://baldan.com.br/es/productos/pna-pala-niveladora-agricola-de-arrastre/
225	Sembradora de Precisión PP SOLO AIR 4000	Baldan	95	3.39	Franco	\N	3200	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-1.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
226	Sembradora de Precisión PP SOLO AIR 4500	Baldan	105	4.06	Franco	\N	4100	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-2.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
227	Sembradora de Precisión PP SOLO AIR 5000	Baldan	135	4.95	Franco	\N	5050	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-3.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
228	Sembradora de Precisión PP SOLO AIR 5500	Baldan	145	5.4	Franco	\N	5450	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-4.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
229	Sembradora de Precisión PP SOLO AIR 6500	Baldan	175	6.3	Franco	\N	7800	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-5.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
230	Sembradora de Precisión PP SOLO AIR 7500	Baldan	185	7.2	Franco	\N	8000	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-air-sembradora-de-precision-6.webp	\N	https://baldan.com.br/es/productos/pp-solo-air-sembradora-de-precision/
232	Sembradora de Precisión PP SOLO 4500	Baldan	105	4.05	Franco	\N	5080	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-2.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
233	Sembradora de Precisión PP SOLO 5000	Baldan	135	4.95	Franco	\N	5820	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-3.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
234	Sembradora de Precisión PP SOLO 5500	Baldan	145	5.4	Franco	\N	6170	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-4.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
235	Sembradora de Precisión PP SOLO 6500	Baldan	175	6.3	Franco	\N	7840	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-5.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
236	Sembradora de Precisión PP SOLO 7500	Baldan	185	7.2	Franco	\N	8690	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-speed-box-sembradora-de-precision-6.webp	\N	https://baldan.com.br/es/productos/pp-solo-speed-box-sembradora-de-precision/
237	Sembradora de Precisión PPS Tercer Deposito 4000	Baldan	95	3.39	Franco	\N	3450	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-1.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
238	Sembradora de Precisión PPS Tercer Deposito 4500	Baldan	105	4.06	Franco	\N	4365	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-2.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
239	Sembradora de Precisión PPS Tercer Deposito 5000	Baldan	135	4.95	Franco	\N	5300	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-3.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
240	Sembradora de Precisión PPS Tercer Deposito 5500	Baldan	145	5.4	Franco	\N	5820	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-4.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
241	Sembradora de Precisión PPS Tercer Deposito 6500	Baldan	175	6.3	Franco	\N	8200	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-5.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
242	Sembradora de Precisión PPS Tercer Deposito 7500	Baldan	185	7.2	Franco	\N	8480	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pp-solo-tercer-deposito-sembradora-de-precision-6.webp	\N	https://baldan.com.br/es/productos/pp-solo-tercer-deposito-sembradora-de-precision/
243	Pulverizador de Barra con Accionamiento Manual Baldan 1,55	Baldan	65	0.002	Franco	\N	296	pulverizador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pulverizador-de-barra-con-accionamiento-manual-baldan-2-1.webp	\N	https://baldan.com.br/es/productos/pulverizador-de-barra-con-accionamiento-manual-baldan-2/
244	Pulverizador Ganadero Baldan 1,5	Baldan	65	0.002	Franco	\N	236	pulverizador	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-pulverizador-ganadero-baldan-1.webp	\N	https://baldan.com.br/es/productos/pulverizador-ganadero-baldan/
245	Desmalezadora de Arrastre con Cardan RAC 1700	Baldan	60	1.7	Franco	\N	800	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-racracd-desmalezadora-de-arrastre-con-cardan-1.webp	\N	https://baldan.com.br/es/productos/racracd-desmalezadora-de-arrastre-con-cardan/
246	Desmalezadora de Arrastre con Cardan RACD 3400	Baldan	70	3.4	Franco	\N	1180	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-racracd-desmalezadora-de-arrastre-con-cardan-2.webp	\N	https://baldan.com.br/es/productos/racracd-desmalezadora-de-arrastre-con-cardan/
247	Desmalezadora Hidráulica Doble Derecha Lateral y Super Lateral RD 2250	Baldan	65	2.25	Franco	\N	650	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral-1.webp	\N	https://baldan.com.br/es/productos/rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral/
248	Desmalezadora Hidráulica Doble Derecha Lateral y Super Lateral RD 2700	Baldan	75	2.7	Franco	\N	760	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral-2.webp	\N	https://baldan.com.br/es/productos/rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral/
249	Desmalezadora Hidráulica Doble Derecha Lateral y Super Lateral RD 3000	Baldan	85	3	Franco	\N	860	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral-3.webp	\N	https://baldan.com.br/es/productos/rd-225027003000-desmalezadora-hidraulica-doble-derecha-lateral-y-super-lateral/
250	Desmalezadora Hidráulica Doble Especial (Derecha)	Baldan	65	2.6	Franco	\N	800	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rdd-e-desmalezadora-hidraulica-doble-especial-derecha-1.webp	\N	https://baldan.com.br/es/productos/rdd-e-desmalezadora-hidraulica-doble-especial-derecha/
251	Desmalezadora Hidráulica Central y Lateral RD / RDU 1300	Baldan	61	1.3	Franco	\N	385	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral-1.webp	\N	https://baldan.com.br/es/productos/rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral/
252	Desmalezadora Hidráulica Central y Lateral RD / RDU 1500	Baldan	73	1.5	Franco	\N	415	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral-2.webp	\N	https://baldan.com.br/es/productos/rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral/
253	Desmalezadora Hidráulica Central y Lateral RD / RDU 1700	Baldan	73	1.7	Franco	\N	456	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral-3.webp	\N	https://baldan.com.br/es/productos/rdrdu-130015001700-desmalezadora-hidraulica-central-y-lateral/
254	Desmalezadora Hidráulica Doble Central y Lateral RPDL 2250	Baldan	65	2.25	Franco	\N	700	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral-1.webp	\N	https://baldan.com.br/es/productos/rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral/
255	Desmalezadora Hidráulica Doble Central y Lateral RPDL 2700	Baldan	75	2.7	Franco	\N	800	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral-2.webp	\N	https://baldan.com.br/es/productos/rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral/
256	Desmalezadora Hidráulica Doble Central y Lateral RPDL 3000	Baldan	85	3	Franco	\N	870	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral-3.webp	\N	https://baldan.com.br/es/productos/rpdl-225027003000-desmalezadora-hidraulica-doble-central-y-lateral/
257	Desmalezadora Hidráulica Central y Lateral RP / RPU 1300	Baldan	61	1.3	Franco	\N	460	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral-1.webp	\N	https://baldan.com.br/es/productos/rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral/
258	Desmalezadora Hidráulica Central y Lateral RP / RPU 1500	Baldan	73	1.5	Franco	\N	500	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral-2.webp	\N	https://baldan.com.br/es/productos/rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral/
259	Desmalezadora Hidráulica Central y Lateral RP / RPU 1700	Baldan	73	1.7	Franco	\N	550	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral-3.webp	\N	https://baldan.com.br/es/productos/rprpu-130015001700-desmalezadora-hidraulica-central-y-lateral/
260	Surcador de Discos Hidráulico	Baldan	72.5	2.5	Franco	330	495	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sd-surcador-de-discos-hidraulico-1.webp	4	https://baldan.com.br/es/productos/sd-surcador-de-discos-hidraulico/
270	Rastra Super Niveladora Control Remoto SNVAM	Baldan	205	6.3	Franco	\N	3510	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-snvam-snvap-rastra-super-niveladora-control-remoto-6.webp	64	https://baldan.com.br/es/productos/snvam-snvap-rastra-super-niveladora-control-remoto/
271	Rastra Super Niveladora Control Remoto SNVAP	Baldan	235	7.1	Franco	\N	3856	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-snvam-snvap-rastra-super-niveladora-control-remoto-16.webp	72	https://baldan.com.br/es/productos/snvam-snvap-rastra-super-niveladora-control-remoto/
275	Rastra Desterronadora y Niveladora con Apertura Hidráulica 42 discos	Baldan	100	3.6	Franco	\N	1019	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-4tv79p-5.webp	42	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora-4tv79p/
272	Rastra Desterronadora y Niveladora con Apertura Hidráulica 28 discos	Baldan	72.5	2.7	Franco	\N	794	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-4tv79p-6.webp	28	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora-4tv79p/
273	Rastra Desterronadora y Niveladora con Apertura Hidráulica 32 discos	Baldan	82.5	3.1	Franco	\N	860	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-4tv79p-7.webp	32	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora-4tv79p/
274	Rastra Desterronadora y Niveladora con Apertura Hidráulica 36 discos	Baldan	95	3.5	Franco	\N	963	harrow	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-sp-rastra-desterronadora-y-niveladora-4tv79p-8.webp	36	https://baldan.com.br/es/productos/sp-rastra-desterronadora-y-niveladora-4tv79p/
291	Sembradora de Precisión Especial 4000	Baldan	85	3.55	Franco	\N	2400	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-spe-top-line-sembradora-de-precision-especial-1.webp	\N	https://baldan.com.br/es/productos/spe-top-line-sembradora-de-precision-especial/
292	Sembradora de Precisión Especial 4500	Baldan	110	4.45	Franco	\N	3000	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-spe-top-line-sembradora-de-precision-especial-2.webp	\N	https://baldan.com.br/es/productos/spe-top-line-sembradora-de-precision-especial/
293	Terrazadora de Arrastre con Control Remoto 14 discos	Baldan	95	3.028	Franco	\N	1885	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto-1.webp	14	https://baldan.com.br/es/productos/tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto/
294	Terrazadora de Arrastre con Control Remoto 16 discos	Baldan	108	3.028	Franco	\N	2028	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto-2.webp	16	https://baldan.com.br/es/productos/tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto/
295	Terrazadora de Arrastre con Control Remoto 18 discos	Baldan	121.5	3.028	Franco	\N	2170	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto-3.webp	18	https://baldan.com.br/es/productos/tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto/
296	Terrazadora de Arrastre con Control Remoto 20 discos	Baldan	135	3.028	Franco	\N	2390	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto-4.webp	20	https://baldan.com.br/es/productos/tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto/
297	Terrazadora de Arrastre con Control Remoto 22 discos	Baldan	148.5	3.028	Franco	\N	2510	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto-5.webp	22	https://baldan.com.br/es/productos/tacr-14-a-22-discos-terrazadora-de-arrastre-con-control-remoto/
298	Terrazadora de Arrastre con Control Remoto Articulado	Baldan	170	0.006	Franco	\N	5202	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-tacr-a-terrazadora-de-arrastre-con-control-remoto-articulado-1.webp	30	https://baldan.com.br/es/productos/tacr-a-terrazadora-de-arrastre-con-control-remoto-articulado/
299	Terraformer remolcado por control remoto TACR Abertura hidráulica	Baldan	315	14.99	Franco	\N	7372	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-terraformer-remolcado-por-control-remoto-4.webp	40	https://baldan.com.br/es/productos/terraformer-remolcado-por-control-remoto/
300	Terraformer remolcado por control remoto TACR Abertura Manual	Baldan	270	12.942	Franco	\N	6411	otro	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-terraformer-remolcado-por-control-remoto-7.webp	34	https://baldan.com.br/es/productos/terraformer-remolcado-por-control-remoto/
282	Sembradora de Precisión 4500	Baldan	130	5.3	Franco	\N	7115	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-topografic-air-sembradora-de-precision-1.webp	\N	https://baldan.com.br/es/productos/topografic-air-sembradora-de-precision/
283	Sembradora de Precisión 5500	Baldan	150	6.4	Franco	\N	8409	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-topografic-air-sembradora-de-precision-2.webp	\N	https://baldan.com.br/es/productos/topografic-air-sembradora-de-precision/
284	Sembradora de Precisión 6500	Baldan	180	7.1	Franco	\N	8793	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-topografic-air-sembradora-de-precision-3.webp	\N	https://baldan.com.br/es/productos/topografic-air-sembradora-de-precision/
285	Sembradora de Precisión 7500	Baldan	195	8.4	Franco	\N	9965	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-topografic-air-sembradora-de-precision-4.webp	\N	https://baldan.com.br/es/productos/topografic-air-sembradora-de-precision/
286	Sembradora de Precisión 8500	Baldan	220	8.9	Franco	\N	10750	seeder	available	2026-09-30 14:21:15.904631	/uploads/implements/baldan-topografic-air-sembradora-de-precision-5.webp	\N	https://baldan.com.br/es/productos/topografic-air-sembradora-de-precision/
\.


--
-- Data for Name: notification; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notification (notification_id, user_id, type, title, message, data, read, created_at) FROM stdin;
1	1	tractor_available	Tractor disponible	El tractor Tractor Direct Upload ahora se encuentra disponible.	{"tractorId": 7}	t	2026-05-20 09:46:19.315413-05
\.


--
-- Data for Name: power_loss; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.power_loss (power_loss_id, query_id, slope_loss_hp, altitude_loss_hp, rolling_resistance_loss_hp, slippage_loss_hp, total_loss_hp, available_power_hp, net_power_hp, efficiency_percentage, calculation_date) FROM stdin;
1	2	1.21	0.88	1.8	0.6	15.43	75	59.57	79.42	2026-04-21 20:41:50.313574
2	3	1.21	0.88	1.8	0.6	15.43	75	59.57	79.42	2026-04-21 20:43:47.669873
3	4	1.21	0.88	1.8	0.6	15.43	75	59.57	79.42	2026-04-21 20:44:36.170109
4	5	1.21	0.88	1.8	0	14.83	75	60.17	80.22	2026-04-29 21:52:47.060598
5	6	1.21	0.88	1.8	0	14.83	75	60.17	80.22	2026-04-29 21:52:54.678982
\.


--
-- Data for Name: query; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.query (query_id, user_id, terrain_id, tractor_id, implement_id, pto_distance_m, carried_objects_weight_kg, working_speed_kmh, query_type, query_date, status) FROM stdin;
2	1	1	1	\N	\N	0	7.5	power_loss	2026-04-21 20:41:50.313574	completed
3	1	1	1	\N	\N	0	7.5	power_loss	2026-04-21 20:43:47.669873	completed
4	1	1	1	\N	\N	0	7.5	power_loss	2026-04-21 20:44:36.170109	completed
5	6	1	1	\N	\N	0	7.5	power_loss	2026-04-29 21:52:47.060598	completed
6	6	1	1	\N	\N	0	7.5	power_loss	2026-04-29 21:52:54.678982	completed
7	1	6	2	\N	\N	0	7.5	implement_power	2026-09-16 18:09:28.206471	completed
1	1	1	1	\N	\N	0	\N	minimum_power	2026-04-21 20:29:40.744101	completed
\.


--
-- Data for Name: query_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.query_history (history_id, user_id, query_id, action_date, action_type, description, result_json) FROM stdin;
1	1	1	2026-04-21 20:29:40.744101	minimum_power_calculation	Cálculo de potencia mínima: 3-body disc plow en Campo La Esperanza	{"queryId": 1, "tractorAnalysis": {"optimalCount": 0, "totalEvaluated": 7, "overpoweredCount": 2, "insufficientCount": 1}, "powerRequirement": {"input": {"terrainData": {"soil_type": "loam", "slope_percentage": 5}, "implementData": {"working_depth_m": 0.25, "power_requirement_hp": 50}}, "factors": {"soilFactor": 1, "basePowerHP": 50, "depthFactor": 1, "slopeFactor": 1.025, "safetyMargin": 0.15}, "minimumPowerHP": 58.94, "calculatedPowerHP": 51.25}, "topRecommendations": [{"name": "John Deere 5075E", "score": "OVERPOWERED", "tractor_id": 1}, {"name": "Massey Ferguson 4709", "score": "OVERPOWERED", "tractor_id": 2}]}
2	1	2	2026-04-21 20:41:50.313574	calculation	Cálculo de potencia: John Deere 5075E en Campo La Esperanza	{"queryId": 2, "netPower": 59.57, "efficiency": 79.42}
3	1	3	2026-04-21 20:43:47.669873	calculation	Cálculo de potencia: John Deere 5075E en Campo La Esperanza	{"queryId": 3, "netPower": 59.57, "efficiency": 79.42}
4	1	4	2026-04-21 20:44:36.170109	calculation	Cálculo de potencia: John Deere 5075E en Campo La Esperanza	{"queryId": 4, "netPower": 59.57, "efficiency": 79.42}
5	6	5	2026-04-29 21:52:47.060598	calculation	Cálculo de potencia: John Deere 5075E en Campo La Esperanza	{"queryId": 5, "netPower": 60.17, "efficiency": 80.22}
6	6	6	2026-04-29 21:52:54.678982	calculation	Cálculo de potencia: John Deere 5075E en Campo La Esperanza	{"queryId": 6, "netPower": 60.17, "efficiency": 80.22}
7	1	7	2026-09-16 18:09:28.206471	implement_power_calculation	Cálculo de potencia por implemento: rastra_pesada_26 con Massey Ferguson 4709 en QA Debug Terrain 800m	{"zoz": {"warnings": [], "axle_loss": 0.22, "pto_power_hp": 51.04, "tractor_type": "4WD", "pto_efficiency": 0.75, "soil_condition": "medio", "traction_loss_hp": 14.97, "slippage_absorbed": true, "rolling_included_in_et": true, "tractor_type_defaulted": false, "combined_drivetrain_loss": 0.39, "gross_to_axle_efficiency": 0.785, "internal_drivetrain_loss_hp": 18.64}, "queryId": 7, "powerKind": "drawbar", "classification": "NO_ADECUADO", "powerRequiredHP": 82.13}
\.


--
-- Data for Name: recommendation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.recommendation (recommendation_id, user_id, terrain_id, tractor_id, implement_id, compatibility_score, observations, work_type, recommendation_date) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role (role_id, role_name, description, status, created_at, updated_at) FROM stdin;
1	admin	System administrator with all permissions	active	2026-04-21 06:46:20.86626	\N
2	user	Standard user with basic permissions	active	2026-04-21 06:46:20.86626	\N
3	operator	Operator with query and calculation permissions	active	2026-04-21 06:46:20.86626	\N
\.


--
-- Data for Name: terrain; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.terrain (terrain_id, user_id, name, area_hectares, altitude_meters, slope_percentage, soil_type, temperature_celsius, registration_date, status, soil_condition) FROM stdin;
1	1	Campo La Esperanza	50	350	5	Loam	25	2026-04-21 20:29:31.538372	active	\N
2	1	Finca El Porvenir	120	800	15	Clay	18	2026-04-21 20:29:31.653629	active	\N
3	1	Lote San Martín	35	150	2	Sand	28	2026-04-21 20:29:31.757174	active	\N
4	1	Parcela La Unión	75	1200	25	Loam	15	2026-04-21 20:29:31.861971	active	\N
5	1	Terreno Las Colinas	200	500	10	Loam	22	2026-04-21 20:29:31.966866	active	\N
6	1	QA Debug Terrain 800m	10	800	5	arcilla	20	2026-09-16 18:08:59.378615	active	\N
\.


--
-- Data for Name: tractor; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tractor (tractor_id, name, brand, model, model_year, engine_power_hp, price, weight_kg, traction_force_kn, traction_type, tire_type, tire_width_mm, tire_diameter_mm, tire_pressure_psi, price_usd, fuel_consumption_lph, maintenance_cost_per_hour, status, registration_date, image_url, has_turbo, ficha_pdf_url, prioridad) FROM stdin;
2912	CaseIH Farmall 90C	CaseIH	farmall 90c	2015	90	\N	3470	30.1	4x4	Radial 18.4R34	467	1658	\N	\N	16.7	\N	available	2026-09-30 16:55:14.40114	https://8968982.fs1.hubspotusercontent-na1.net/hub/8968982/hubfs/20220714092836_1504_case_farmall_90jxm_studio_stvalentin_6.jpg?width=600&name=20220714092836_1504_case_farmall_90jxm_studio_stvalentin_6.jpg	f	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2021/CIH_FOLLETO_TRACTOR_FARMALL_80-90-100.pdf#page=9	t
2	Massey Ferguson 4709	Massey Ferguson	4709	2022	90	72000	3508	28.6	4x4	Radial 420/85R30	420	1476	\N	72000	15	6.5	available	2026-04-21 06:46:20.86626	/uploads/tractors/td8855.webp	f	\N	f
1001	Massey Ferguson 675	Massey Ferguson	675	1983	70	\N	3628	22	4x4	Diagonal 83 - 19	2108	4067	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10076.webp	f	\N	f
1009	Kubota M105GX-IV	Kubota	M105GX IV	2016	111	\N	4300	40.7	4x4	Radial 520/70R34	520	1592	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10103.webp	t	\N	f
1010	Kubota M115GX-IV	Kubota	M115GX IV	2016	123	\N	4844	45.1	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10104.webp	t	\N	f
1011	Kubota M125GX-IV	Kubota	M125GX IV	2016	133	\N	4844	48.8	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10105.webp	t	\N	f
1003	Kubota M95GX-III	Kubota	M95GX III	2016	104	\N	4300	38.2	4x4	Radial 520/70R34	520	1592	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10097.webp	t	\N	f
1004	Kubota M105GX-III	Kubota	M105GX III	2016	111	\N	4300	40.7	4x4	Radial 520/70R34	520	1592	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10098.webp	t	\N	f
1005	Kubota M115GX-III	Kubota	M115GX III	2016	123	\N	4809	45.1	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10099.webp	t	\N	f
23	John Deere 8440	John Deere	8440	1979	215	\N	12061	112.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	42.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td101.webp	t	\N	f
1006	Kubota M125GX-III	Kubota	M125GX III	2016	133	\N	4809	48.8	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10100.webp	t	\N	f
1007	Kubota M135GX-III	Kubota	M135GX III	2016	143	\N	4809	52.5	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10101.webp	t	\N	f
1008	Kubota M95GX-IV	Kubota	M95GX IV	2016	104	\N	4300	38.2	4x4	Radial 520/70R34	520	1592	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10102.webp	t	\N	f
1012	Kubota M135GX-IV	Kubota	M135GX IV	2016	143	\N	4844	52.5	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10106.webp	t	\N	f
1013	Kubota M7-132	Kubota	M7 132	2018	130	\N	6300	65	4x4	Radial 650/65R38	650	1810	\N	\N	28	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10107.webp	t	\N	f
1014	Kubota M7-152	Kubota	M7 152	2018	150	\N	6300	65.3	4x4	Radial 650/65R38	650	1810	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10108.webp	t	\N	f
2938	Fiat 400E	Fiat	400E	1974	45	\N	1930	16.5	4x2	Diagonal 74 - 19	1880	3678	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10311.webp	f	\N	f
1015	Kubota M7-172	Kubota	M7 172	2018	170	\N	6300	75.8	4x4	Radial 650/65R38	650	1810	\N	\N	32.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10109.webp	t	\N	f
1016	Kubota M4062	Kubota	M4062	2018	66	\N	2570	24.2	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10110.webp	f	\N	f
1017	Kubota M4072	Kubota	M4072	2018	74	\N	2570	27.1	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10111.webp	f	\N	f
1018	Kubota M5091	Kubota	M5091	2016	75	\N	3420	27.5	4x4	Radial 360/70R24	360	1114	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10112.webp	f	\N	f
1019	Kubota M5111	Kubota	M5111	2016	113	\N	3420	41.5	4x4	Radial 360/70R24	360	1114	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10113.webp	f	\N	f
1020	Kubota M5071N	Kubota	M5071N	2000	73	\N	2500	26.8	4x4	Radial 440/65R28	440	1283	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10114.webp	f	\N	f
1021	Kubota M5091N	Kubota	M5091N	2000	92	\N	2500	33.8	4x4	Radial 440/65R28	440	1283	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10115.webp	f	\N	f
1022	Kubota M5101N	Kubota	M5101N	2000	103	\N	2500	37.8	4x4	Radial 440/65R28	440	1283	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10116.webp	f	\N	f
1023	Massey Ferguson 42	Massey Ferguson	42	1962	42	\N	1650	15.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10130.webp	f	\N	f
1024	Massey Ferguson 865	Massey Ferguson	865	2000	49	\N	1920	18	4x2	Diagonal 11x32	279	1288	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10131.webp	f	\N	f
1025	Kubota ST-30	Kubota	ST 30	1997	28.7	\N	889	8.5	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10133.webp	f	\N	f
1026	Kubota STV32	Kubota	STV32	2006	32.3	\N	975	8.7	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10136.webp	f	\N	f
1027	Kubota STV36	Kubota	STV36	2006	35.9	\N	975	9.9	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10137.webp	f	\N	f
1028	Kubota STV40	Kubota	STV40	2006	34.7	\N	975	11.2	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10138.webp	f	\N	f
1029	Kubota STW34	Kubota	STW34	2006	32.9	\N	1104	8.2	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10139.webp	f	\N	f
2933	Fiat G170	Fiat	G170	1993	170	\N	7166	77.3	4x4	Diagonal 93 - 20	2362	4524	\N	\N	34.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10286.webp	t	\N	f
732	Massey Ferguson 35 (1960-1964)	Massey Ferguson	35	1960	37	\N	1402	13.6	4x2	Diagonal 10-28	254	1143	\N	\N	9.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7529.webp	f	\N	f
757	Massey Ferguson 180	Massey Ferguson	180	1964	64	\N	3032	27.1	4x2	Diagonal 15.5-38	394	1634	\N	\N	14.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td749.webp	f	\N	f
784	Massey Ferguson 245	Massey Ferguson	245	1976	45	\N	1769	19	4x2	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td760.webp	f	\N	f
2934	Fiat G190	Fiat	G190	1993	190	\N	7529	0.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10287.webp	t	\N	f
2935	Fiat G210	Fiat	G210	1993	210	\N	7575	82.5	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10288.webp	t	\N	f
2936	Fiat G240	Fiat	G240	1993	240	\N	7688	124.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	43.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10289.webp	t	\N	f
2153	CaseIH Steiger 500	CaseIH	Steiger 500	2011	507	\N	19982	207.6	4x4	Diagonal 1-3	25	119	\N	\N	101.8	\N	available	2026-09-30 16:49:10.296204	https://i.machinio.com/medium/cmm/4001/case-ih-steiger-500-tractor-f8ae68e82543.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
2165	CaseIH Puma 200	CaseIH	Puma 200	2011	197	\N	8591	71.4	4x4	Diagonal 11 - 20	279	983	\N	\N	38.6	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/d07e46736ff446959945690954d6ffbe?v=81599384	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA%20LWB.pdf#page=11	t
2166	CaseIH Puma 215	CaseIH	Puma 215	2011	213	\N	8110	72.7	4x4	Diagonal 11 - 20	279	983	\N	\N	40.1	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/2264fd7eb05c45d088c18d2e9ab24d8b?v=fea8f672	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA%20LWB.pdf#page=11	t
2167	CaseIH Puma 230	CaseIH	Puma 230	2011	234	\N	8981	81.2	4x4	Diagonal 11 - 20	279	983	\N	\N	43.9	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/fe06e77a510b41ef92f49a0f78d3ae1d?v=a427e465	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA%20LWB.pdf#page=11	t
2840	CaseIH Steiger 470	CaseIH	steiger 470	2014	477	\N	18216	193.5	4x4	Radial 710/70R42	710	2061	\N	\N	95.8	\N	available	2026-09-30 16:51:28.845746	https://assets.revistacultivar.com.br/877e37ec-0a8d-4eea-9bf7-74ca0899d05e.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
1549	Kubota M7040	Kubota	M7040	2007	70	\N	2400	22.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://dieselkubota.com.co/wp-content/uploads/2017/02/WhatsApp-Image-2023-11-16-at-8.13.36-AM-min-300x300.jpeg	t	https://dieselkubota.com.co/wp-content/uploads/2023/11/Tractor-Kubota-M7040-nueva-generacion.pdf	t
62	John Deere 2040S	John Deere	2040S	1981	75	\N	3626	24.2	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td103.webp	f	\N	f
1047	Massey Ferguson 154S	Massey Ferguson	154S	1986	42	\N	2190	15.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10300.webp	f	\N	f
1048	Kubota T22	Kubota	T22	2000	21.6	\N	879	7.9	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10304.webp	f	\N	f
2939	Fiat 800E	Fiat	800E	1974	90	\N	3140	33	4x2	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10312.webp	f	\N	f
1054	Kubota M8-201	Versatile	m8 201	2000	200	\N	8849	97.3	4x4	Diagonal 8-20	203	853	\N	\N	39.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10333.webp	f	\N	f
4516	Kubota M9540 Sin Cabina	Kubota	M9540 Sin Cabina	\N	95	\N	3125	29.8	4x2	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-10-02 06:10:11.789532	https://dieselkubota.com.co/wp-content/uploads/2018/11/20230629_103240-min-300x300.jpg	t	https://dieselkubota.com.co/wp-content/uploads/2023/09/Kubota-M9540-G4_compressed.pdf	t
3236	Fiat 1380	Fiat	1380	1979	135	\N	6051	49.5	4x4	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2001.webp	t	\N	f
423	Massey Ferguson 6465	Massey Ferguson	6465	2004	118	\N	5013	45.2	4x4	Diagonal 04 - 20	102	681	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3912.webp	t	\N	f
433	Massey Ferguson 5460SA	Massey Ferguson	5460SA	2004	105	\N	3905	33	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3925.webp	t	\N	f
443	Massey Ferguson GC2300	Iseki	ferguson gc2300	2003	22.5	\N	620	6.9	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3935.webp	f	\N	f
1737	New Holland TT45A	New Holland	TT45A	2007	40	\N	1632	12.8	4x2	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3972.webp	f	\N	f
450	John Deere 40C	John Deere	40C	1953	21.24	\N	2041	20.1	track	Diagonal 53 - 19	1346	2771	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td40.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1075/	f
500	John Deere 310	John Deere	310	1966	31.6	\N	2095	11.6	4x2	Diagonal 66 - 19	1676	3332	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4824.webp	f	\N	f
504	John Deere 2141	John Deere	2141	1982	76.4	\N	3946	28	4x4	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4837.webp	f	\N	f
510	John Deere 3351	John Deere	3351	1987	99.2	\N	5193	32.5	4x4	Diagonal 87 - 19	2210	4239	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4845.webp	f	\N	f
537	John Deere 420C	John Deere	420C	1956	28.76	\N	1877	21.6	track	Diagonal 56 - 19	1422	2901	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5143.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1087/	f
1960	CaseIH Steiger 380	CaseIH	Steiger 380	2007	380	\N	17191	184	4x4	Diagonal 07 - 20	178	810	\N	\N	85.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5983.webp	t	\N	f
1968	CaseIH Magnum 305	CaseIH	Magnum 305	2008	304	\N	9357	110	4x4	Diagonal 08 - 20	203	853	\N	\N	64.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5991.webp	t	\N	f
1976	Massey Ferguson 188	Massey Ferguson	188	1972	75	\N	3279	25.7	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6041.webp	f	\N	f
2120	New Holland T6040 Elite	New Holland	T6040 Elite	2007	120	\N	4938	55.7	4x4	Diagonal 07 - 20	178	810	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6657.webp	t	\N	f
730	John Deere 2025R	John Deere	2025R	2013	24.2	\N	752	6.6	4x4	Diagonal 31x12	787	1643	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7282.webp	f	\N	f
2266	New Holland T6020 Delta	New Holland	T6020 Delta	2007	110	\N	4279	40.9	4x4	Diagonal 07 - 20	178	810	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7285.webp	t	\N	f
2279	Kubota BX2670	Kubota	BX2670	2013	25.5	\N	664	7.2	4x4	Diagonal 13 - 20	330	1069	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7305.webp	f	\N	f
2331	New Holland T8.420	New Holland	T8.420	2013	367	\N	13682	126.7	4x4	Diagonal 13 - 20	330	1069	\N	\N	69.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7515.webp	t	\N	f
816	John Deere 6175R (2011-2014)	John Deere	6175R	2011	175	\N	8299	64.2	4x4	Diagonal 15 - 20	381	1156	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9480.webp	t	\N	f
1032	Ford 846	Ford	846	1989	230	\N	8164	74.1	4x4	Diagonal 18.4x42	467	1861	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10145.webp	t	\N	f
1101	Massey Ferguson 451	Massey Ferguson	ferguson 451	2002	48	\N	2375	16.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10555.webp	f	\N	f
1102	Massey Ferguson 471	Massey Ferguson	ferguson 471	2002	65	\N	2859	21.6	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10556.webp	f	\N	f
1103	Massey Ferguson 481	Massey Ferguson	ferguson 481	2002	75	\N	2879	25.3	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10557.webp	f	\N	f
2887	CaseIH Farmall 55C Series II	CaseIH	farmall 55c	2000	55	\N	1710	17.1	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10571.webp	t	\N	f
2888	CaseIH Vestrum 100	CaseIH	vestrum 100	2000	98.6	\N	5851	27.9	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10572.webp	t	\N	f
2889	CaseIH Vestrum 130	CaseIH	vestrum 130	2000	128.2	\N	5851	40.7	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10573.webp	t	\N	f
818	John Deere 6215R (2011-2014)	John Deere	6215R	2011	215	\N	8500	78.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	42.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9482.webp	t	\N	f
74	John Deere 8R 230	John Deere	8R 230	2000	230	\N	12610	66.8	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10634.webp	t	\N	f
75	John Deere 8R 250	John Deere	8R 250	2014	250	\N	12610	73.4	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10635.webp	t	\N	f
76	John Deere 8R 280	John Deere	8R 280	2014	280	\N	12610	83.6	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10636.webp	t	\N	f
77	John Deere 8R 310	John Deere	8R 310	2014	310	\N	12610	94.3	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10637.webp	t	\N	f
1038	Massey Ferguson 1088	Massey Ferguson	1088	1972	87	\N	5115	31.9	4x2	Diagonal 23.1x30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10153.webp	f	\N	f
1039	Massey Ferguson 1095	Massey Ferguson	1095	1972	95	\N	5426	34.9	4x2	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10154.webp	f	\N	f
78	John Deere 8R 340	John Deere	8R 340	2014	340	\N	12610	119.3	4x4	Radial 480/80R50	480	2038	\N	\N	64.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10638.webp	t	\N	f
79	John Deere 8R 370	John Deere	8R 370	2014	370	\N	12610	125.3	4x4	Radial 480/80R50	480	2038	\N	\N	70.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10639.webp	t	\N	f
1109	Massey Ferguson 1835M	Massey Ferguson	ferguson 1835m	2020	36.2	\N	1574	10.1	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10720.webp	t	\N	f
4513	Kubota MU4501 (4WD)	Kubota	MU4501 (4WD)	\N	45	\N	1970	14.1	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-10-02 06:10:11.789532	https://dieselkubota.com.co/wp-content/uploads/2019/11/MU4501-4X4-300x300.png	f	https://dieselkubota.com.co/wp-content/uploads/2019/11/Ficha_TRACTOR_MU4501-4WD.pdf	t
4514	Kubota MU5501 (4WD)	Kubota	MU5501 (4WD)	\N	55	\N	2380	17.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-10-02 06:10:11.789532	https://dieselkubota.com.co/wp-content/uploads/2019/11/MU5501-4WD-300x300.png	f	https://dieselkubota.com.co/wp-content/uploads/2019/11/Ficha_TRACTOR_MU5501-4WD.pdf	t
1110	Massey Ferguson 1840M	Massey Ferguson	ferguson 1840m	2020	39.4	\N	1574	11	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10721.webp	t	\N	f
4543	New Holland 7630	New Holland	7630	\N	108	\N	3630	33.8	4x2	Diagonal 8-2	203	396	\N	\N	\N	\N	available	2026-10-02 06:10:11.789532	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/20120503132509_1S_7630_00450E.jpg	t	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/7630.pdf	t
1884	Kubota B2320	Kubota	B2320	2008	23	\N	630	6.6	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://dieselkubota.com.co/wp-content/uploads/2017/02/B2420-300x300.jpg	f	https://dieselkubota.com.co/wp-content/uploads/2015/02/B2420-1.pdf	t
1559	Kubota L3400	Kubota	L3400	2004	34.7	\N	1380	10.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://dieselkubota.com.co/wp-content/uploads/2015/06/L-3400.-300x300.jpg	f	http://dieselkubota.com.co/wp-content/uploads/2015/06/FICHA-TECNICA-L3408-1.pdf	t
1111	Massey Ferguson 2850M	Massey Ferguson	ferguson 2850m	2020	48.8	\N	1830	14	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10722.webp	t	\N	f
1112	Massey Ferguson 2855M	Massey Ferguson	ferguson 2855m	2020	53.6	\N	1830	14.7	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10723.webp	t	\N	f
1041	Massey Ferguson 5410	Massey Ferguson	ferguson 5410	2011	73.8	\N	3700	27.1	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10156.webp	t	\N	f
1042	Massey Ferguson 5420	Massey Ferguson	ferguson 5420	2011	79	\N	3800	29	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10157.webp	t	\N	f
1043	Massey Ferguson 5430	Massey Ferguson	ferguson 5430	2011	88.8	\N	3800	32.6	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10158.webp	t	\N	f
1236	Kubota L3001	Kubota	L3001	1976	29.6	\N	1224	10.9	4x4	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11454.webp	f	\N	f
22	John Deere 5415	John Deere	5415	2001	75	\N	2688	24.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10067.webp	f	\N	f
1044	Massey Ferguson 5440	Massey Ferguson	ferguson 5440	2011	98.7	\N	3800	36.2	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10159.webp	t	\N	f
1045	Massey Ferguson 5450	Massey Ferguson	ferguson 5450	2011	103.7	\N	3900	38	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10160.webp	t	\N	f
28	John Deere 8640	John Deere	8640	1979	275	\N	12823	123.6	4x4	Diagonal 18.4-34	467	1658	\N	\N	55.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td102.webp	t	\N	f
29	John Deere 20C	John Deere	20C	2009	18.5	\N	1399	4.4	4x2	Diagonal 8.25x16	210	763	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10222.webp	f	\N	f
1113	Massey Ferguson 2860M	Massey Ferguson	ferguson 2860m	2020	60.3	\N	1945	17.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10724.webp	t	\N	f
1117	Massey Ferguson 8S.205	Massey Ferguson	ferguson 8s205	2000	202.5	\N	8700	67.4	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10729.webp	t	\N	f
1226	Kubota L3902	Kubota	L3902	2014	37.5	\N	1255	11.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11396.webp	f	\N	f
1227	Kubota L4802	Kubota	L4802	2014	48.4	\N	1554	14.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11397.webp	f	\N	f
2994	CaseIH Farmall 25SC	LS	farmall 25sc	2000	24.7	\N	654	6.3	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11399.webp	f	\N	f
125	John Deere 1250	Yanmar	deere 1250	1982	44	\N	2211	23	4x4	Diagonal 14.9-28	378	1355	\N	\N	9.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td114.webp	f	\N	f
1228	CaseIH MX240 Magnum	CaseIH	MX240 Magnum	1999	205	\N	9162	93.1	4x4	Radial 20.8R42	528	1965	\N	\N	48.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1140.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1227/	f
1229	New Holland T5.90	New Holland	holland t590	2000	90	\N	3480	26.8	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11401.webp	t	\N	f
1230	New Holland T5.100	New Holland	holland t5100	2013	100	\N	3480	31.2	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11402.webp	t	\N	f
1060	New Holland T5.110 (2013-2016)	New Holland	holland t5110	2013	110	\N	3480	34.1	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11403.webp	t	\N	f
1066	New Holland T5.120 (2013-2016)	New Holland	holland t5120	2013	120	\N	3480	36.7	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11404.webp	t	\N	f
1231	CaseIH 244	Mitsubishi	244	1984	18	\N	861	6.6	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1141.webp	f	\N	f
127	John Deere 5120M	John Deere	5120M	2015	120	\N	3975	38.5	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11410.webp	f	\N	f
128	John Deere 5130M	John Deere	5130M	2000	130	\N	4166	42.2	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11411.webp	f	\N	f
1232	CaseIH 245	Mitsubishi	245	1986	21	\N	866	6.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1142.webp	f	\N	f
1234	CaseIH 255	Mitsubishi	255	1986	24	\N	950	7.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1144.webp	f	\N	f
1235	CaseIH 265	CaseIH	265	1987	27	\N	1274	8.8	4x2	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1145.webp	f	\N	f
1237	CaseIH MX270 Magnum	CaseIH	MX270 Magnum	1999	235	\N	9162	96.4	4x4	Radial 20.8R42	528	1965	\N	\N	56	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1146.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1229/	f
1238	Massey Ferguson 292	Massey Ferguson	292	1994	105	\N	3256	34.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11469.webp	t	\N	f
1239	CaseIH 275	Mitsubishi	275	1986	31	\N	1270	9.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1147.webp	f	\N	f
1240	Massey Ferguson 4275	Massey Ferguson	ferguson 4275	2010	75	\N	4567	24.6	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11471.webp	f	\N	f
1241	Massey Ferguson 4283	Massey Ferguson	ferguson 4283	2010	85	\N	4829	26.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11472.webp	f	\N	f
21	John Deere 950	Yanmar	deere 950	1978	31	\N	1360	13.6	4x4	Diagonal 12.4-28	315	1247	\N	\N	6.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td100.webp	f	\N	f
1262	CaseIH 885	CaseIH	885	1985	84	\N	3560	26.4	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1156.webp	f	\N	f
1242	Massey Ferguson 4290	Massey Ferguson	ferguson 4290	2010	85	\N	5410	26.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11473.webp	f	\N	f
1243	Massey Ferguson 4291	Massey Ferguson	ferguson 4291	2010	100	\N	5445	32.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11474.webp	t	\N	f
1247	CaseIH 385	CaseIH	385	1985	43	\N	2235	12.8	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1148.webp	f	\N	f
1248	CaseIH 395	CaseIH	395	1991	46	\N	2235	12.8	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1149.webp	f	\N	f
129	John Deere 1450	Yanmar	deere 1450	1984	55	\N	2299	23.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	11.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td115.webp	f	\N	f
1249	CaseIH 485	CaseIH	485	1985	53	\N	2358	15.8	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1150.webp	f	\N	f
1251	Massey Ferguson 4320	Massey Ferguson	ferguson 4320	2001	64	\N	2634	23.5	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11503.webp	t	\N	f
1252	CaseIH 495	CaseIH	495	1991	53	\N	2762	15.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1151.webp	f	\N	f
1253	CaseIH 585	CaseIH	585	1985	60	\N	3068	19.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1152.webp	f	\N	f
1254	CaseIH 595	CaseIH	595	1991	60	\N	3032	19.1	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1153.webp	f	\N	f
1255	CaseIH 685	CaseIH	685	1985	68.1	\N	4012	32.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1154.webp	f	\N	f
2996	CaseIH Magnum 400	CaseIH	magnum 400	2019	396	\N	15800	131.7	4x4	Radial 480/80R50	480	2038	\N	\N	75.7	\N	available	2026-09-30 18:02:54.57488	https://assets.machinerypete.com/uploads/image/processed_image/33179947/full_size_img.axd	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Produtos/Tratores/Linha-Magnum/Magnum%20AFS/CIH_Folleto-Magnum-AFS-Connect-Espanol.pdf#page=13	t
1261	CaseIH 695	CaseIH	695	1991	72	\N	3440	22.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1155.webp	f	\N	f
1263	Massey Ferguson 22-20GC	MTD	ferguson 22 20gc	2007	20	\N	658	5.9	4x2	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11568.webp	f	\N	f
1265	CaseIH 895	CaseIH	895	1991	84	\N	3276	26.4	4x4	Diagonal 16.9-24	429	1339	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1157.webp	f	\N	f
2926	Fiat 45-66S	Fiat	45 66S	1992	44.4	\N	2375	16.3	4x4	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10016.webp	f	\N	f
1266	CaseIH 995	CaseIH	995	1991	104	\N	3276	31.2	4x4	Radial 14.9R24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1158.webp	t	\N	f
1268	CaseIH 1120	Mitsubishi	1120	1986	19	\N	625	6.1	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1159.webp	f	\N	f
1264	Massey Ferguson 22-28GC	MTD	ferguson 22 28gc	2007	28	\N	908	7.7	4x4	Diagonal 12.00-15	305	899	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11569.webp	f	\N	f
1272	CaseIH 1140	Mitsubishi	1140	1986	27	\N	934	8.4	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1161.webp	f	\N	f
1273	CaseIH 1394	CaseIH	1394	1985	77	\N	3166	23.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1162.webp	t	\N	f
3013	Fiat 25R	Fiat	25R	1951	23	\N	1379	8.4	4x2	Diagonal 51 - 19	1295	2685	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11637.webp	f	\N	f
1033	Ford 876	Ford	876	1989	280	\N	8210	123.2	4x4	Diagonal 18.4x38	467	1760	\N	\N	51.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10146.webp	t	\N	f
1034	Ford 946	Ford	946	1989	325	\N	14742	104.9	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10147.webp	t	\N	f
1035	Ford 976	Ford	976	1989	360	\N	9570	115.9	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10148.webp	t	\N	f
1036	Kubota B2301	Kubota	B2301	2000	22	\N	710	6.4	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10150.webp	f	\N	f
1037	Kubota B2601	Kubota	B2601	2000	25.5	\N	740	7.2	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10151.webp	f	\N	f
1040	Massey Ferguson 1098	Massey Ferguson	1098	1972	106	\N	6026	38.9	4x2	Diagonal 24.5x32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10155.webp	f	\N	f
3014	Fiat 312R	Fiat	312R	1959	30	\N	1420	11	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11639.webp	f	\N	f
2883	CaseIH Farmall 110N	CaseIH	Farmall 110N	2014	106	\N	2854	34.1	4x4	Radial 14.9R28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10203.webp	t	\N	f
2881	CaseIH Farmall 80N	CaseIH	Farmall 80N	2009	80	\N	3470	22.7	4x4	Radial 14.9R28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	https://lh4.googleusercontent.com/proxy/BTVG0S5PVMzrDxkU4OkK-IKw6dwISMfsm__j4y5kEyDl2flmWRuiohOYU-nlWFuq6PDq9qf_ylDiMmkWS72VLRNJQT_CKxFrhdg99uYgk8OvlsSkFgEWsorFFw	f	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2021/CIH_FOLLETO_TRACTOR_FARMALL_80-90-100.pdf#page=9	t
2882	CaseIH Farmall 100N	CaseIH	Farmall 100N	2009	101	\N	3630	31.6	4x4	Radial 14.9R28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	https://assets.cnhindustrial.com/caseih/MEXICO/MEXICOASSETS/Our-Products/Tractors/Farmall-JX-Series/Farmall-JX100-MFD_CAB/FARMALL_JX100_MFD_CAB.jpg	f	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2021/CIH_FOLLETO_TRACTOR_FARMALL_80-90-100.pdf#page=9	t
130	John Deere 1650	Yanmar	deere 1650	1984	67	\N	2100	29.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	12.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td116.webp	t	\N	f
1271	CaseIH 1130	Mitsubishi	1130	1986	23	\N	907	7.3	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1160.webp	f	\N	f
1274	Kubota M7-134	Kubota	M7 134	2020	100	\N	6598	36.7	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11627.webp	t	\N	f
1275	Kubota M7-154	Kubota	M7 154	2020	120	\N	6598	44	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11628.webp	t	\N	f
1276	Kubota M7-174	Kubota	M7 174	2020	140	\N	6598	51.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11629.webp	t	\N	f
1277	CaseIH 1494	CaseIH	1494	1983	85	\N	4536	27.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1163.webp	t	\N	f
1278	CaseIH 1594	CaseIH	1594	1985	97	\N	4213	37	4x2	Diagonal 16.9-38	429	1695	\N	\N	19.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1164.webp	f	\N	f
2884	CaseIH Farmall 80V	CaseIH	Farmall 80V	2000	80	\N	3470	23.8	4x4	Radial 11.2R24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	https://lh4.googleusercontent.com/proxy/BTVG0S5PVMzrDxkU4OkK-IKw6dwISMfsm__j4y5kEyDl2flmWRuiohOYU-nlWFuq6PDq9qf_ylDiMmkWS72VLRNJQT_CKxFrhdg99uYgk8OvlsSkFgEWsorFFw	f	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2021/CIH_FOLLETO_TRACTOR_FARMALL_80-90-100.pdf#page=9	t
32	John Deere 2026R	John Deere	2026R	2000	25.2	\N	760	6.6	4x4	Diagonal 280/70-16	280	798	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10233.webp	f	\N	f
33	John Deere 2036R	John Deere	2036R	2016	36.6	\N	1099	11	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10234.webp	t	\N	f
35	John Deere 3038R	John Deere	3038R	2000	37.1	\N	1399	11	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10236.webp	t	\N	f
36	John Deere 3045R	John Deere	3045R	2000	44.6	\N	1399	12.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10237.webp	t	\N	f
39	John Deere 1046	Goldini	deere 1046	1996	37	\N	1119	13.6	4x4	Radial 12.4R20	315	1043	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10242.webp	f	\N	f
1063	Kubota M1-100	Kubota	M1 100	1988	100	\N	3989	33	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10352.webp	f	\N	f
1279	CaseIH 1896	CaseIH	1896	1985	95	\N	6121	55	4x4	Diagonal 18.4-38	467	1760	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1165.webp	t	\N	f
1280	New Holland TI4.50	Goldoni	holland ti450	2014	47	\N	1650	17.2	4x2	Diagonal 270/70-18	270	835	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11655.webp	f	\N	f
1281	New Holland TI4.65	Goldoni	holland ti465	2014	65.2	\N	1769	23.9	4x2	Diagonal 280/70-18	280	849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11656.webp	t	\N	f
1282	Kubota L1-345	Kubota	L1 345	1987	34	\N	1510	12	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11657.webp	t	\N	f
1283	Kubota L1-385	Kubota	L1 385	1987	38	\N	1730	13.5	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11658.webp	f	\N	f
1284	Kubota L1-435	Kubota	L1 435	1987	43	\N	1515	15.2	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11659.webp	t	\N	f
1285	CaseIH 2096	CaseIH	2096	1985	116	\N	5386	57.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1166.webp	t	\N	f
1286	Kubota L1-455	Kubota	L1 455	1987	45	\N	1779	15.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11660.webp	f	\N	f
37	John Deere 846	Goldini	deere 846	1996	27	\N	1080	9.9	4x4	Diagonal 96 - 20	2438	4653	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10240.webp	f	\N	f
38	John Deere 946	Goldini	deere 946	1996	30	\N	1080	11	4x4	Diagonal 96 - 20	2438	4653	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10241.webp	f	\N	f
2942	Fiat 665C	Fiat	665C	1982	66	\N	3415	24.2	track	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10396.webp	f	\N	f
2943	Fiat 765C	Fiat	765C	1982	77	\N	4100	28.3	track	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10397.webp	f	\N	f
2944	Fiat 70-65	Fiat	70 65	1985	70	\N	3700	25.7	track	Diagonal 85 - 19	2159	4153	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10400.webp	f	\N	f
2945	Fiat 80-65	Fiat	80 65	1985	78.9	\N	4100	28.9	track	Diagonal 85 - 19	2159	4153	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10401.webp	f	\N	f
1064	Kubota M1-115	Kubota	M1 115	1988	115	\N	4130	37.8	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10353.webp	f	\N	f
1065	Kubota B72	Kubota	B72	1998	16.2	\N	570	5.9	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10354.webp	f	\N	f
1091	Massey Ferguson 2225	Massey Ferguson	2225	2002	68	\N	3050	24.9	4x4	Radial 420/70R30	420	1350	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10493.webp	f	\N	f
80	John Deere 8R 410	John Deere	8R 410	2016	410	\N	13630	135.5	4x4	Radial 480/80R50	480	2038	\N	\N	71.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10640.webp	t	\N	f
1287	CaseIH 2130	Carraro	2130	1988	47	\N	1860	17.2	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1167.webp	f	\N	f
3015	J.I. Case 10-20	Case IH	10 20	1915	20	\N	2222	11.7	4x2	Diagonal 52x22	1321	2804	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11673.webp	f	\N	f
3016	J.I. Case 12-25	Case IH	12 25	1914	25	\N	4082	9.2	4x2	Diagonal 56x18	1422	2875	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11674.webp	f	\N	f
1288	CaseIH 2140	Carraro	2140	1988	55	\N	2170	20.2	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1168.webp	f	\N	f
1289	CaseIH 2150	Carraro	2150	1988	64	\N	2140	23.5	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1169.webp	f	\N	f
1290	Kubota MX4900	Kubota	MX4900	2000	51.8	\N	1685	15.2	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11695.webp	t	\N	f
1291	Kubota ME5700	Kubota	ME5700	2003	62.5	\N	2469	19.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11696.webp	f	\N	f
1292	Kubota ME8200	Kubota	ME8200	2003	86.7	\N	3549	27.2	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11697.webp	t	\N	f
1293	Kubota ME9000	Kubota	ME9000	2003	93.8	\N	3556	29.8	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11698.webp	t	\N	f
131	John Deere 2150	John Deere	2150	1983	45	\N	2571	21.7	4x4	Diagonal 16.9-28	429	1441	\N	\N	12.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td117.webp	f	\N	f
1294	CaseIH 2294	CaseIH	2294	1984	154	\N	5021	57.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	33.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1170.webp	t	\N	f
1297	CaseIH 2394	CaseIH	2394	1984	197	\N	6472	68.9	4x2	Diagonal 18.4x38	467	1760	\N	\N	39.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1171.webp	t	\N	f
2949	Fiat 80-75	Fiat	80 75	1989	78.9	\N	3949	28.9	track	Diagonal 89 - 19	2261	4326	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10405.webp	f	\N	f
2953	Belarus T-40	Belarus	T 40	1961	37	\N	2599	13.6	4x4	Diagonal 11-38	279	1440	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10487.webp	f	\N	f
1052	Massey Ferguson 194F	Massey Ferguson	194F	1986	68	\N	2429	24.9	4x4	Diagonal 16.9-24	429	1339	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10310.webp	f	\N	f
63	John Deere 3025D	John Deere	3025D	2000	24.4	\N	1260	7.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10314.webp	f	\N	f
1067	Kubota GL-35	Kubota	GL 35	1991	35	\N	1574	12.8	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10364.webp	f	\N	f
1118	Massey Ferguson 8S.225	Massey Ferguson	ferguson 8s225	2000	221.3	\N	8700	71.8	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10730.webp	t	\N	f
1119	Massey Ferguson 8S.245	Massey Ferguson	ferguson 8s245	2000	241.4	\N	8700	78.2	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10731.webp	t	\N	f
1120	Massey Ferguson 8S.265	Massey Ferguson	ferguson 8s265	2000	261.5	\N	8700	83.6	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10732.webp	t	\N	f
1121	Massey Ferguson 1825E	Massey Ferguson	ferguson 1825e	2020	24	\N	1210	7.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10755.webp	f	\N	f
90	John Deere 6210SE	John Deere	6210SE	1998	90	\N	3958	33	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10778.webp	t	\N	f
91	John Deere 6310SE	John Deere	6310SE	1998	100	\N	4047	36.7	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10779.webp	t	\N	f
92	John Deere 6410SE	John Deere	6410SE	1998	105	\N	4077	38.5	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10780.webp	t	\N	f
1126	Kubota MX5400	Kubota	MX5400	2000	55.5	\N	1685	17.1	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10899.webp	t	\N	f
94	John Deere 8650	John Deere	8650	1982	290	\N	13299	125.7	4x4	Diagonal 24.5-32	622	1871	\N	\N	58.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td109.webp	t	\N	f
1127	Kubota MX6000	Kubota	MX6000	2000	63.4	\N	1693	19	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10900.webp	t	\N	f
1128	Kubota B2401	Kubota	B2401	2000	21.9	\N	689	7	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10901.webp	f	\N	f
1307	Massey Ferguson 1520	Iseki	ferguson 1520	2018	19.5	\N	669	6.1	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11719.webp	f	\N	f
1308	CaseIH 2594	CaseIH	2594	1984	217	\N	6747	75.1	4x2	Diagonal 20.8x38	528	1863	\N	\N	45.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1172.webp	t	\N	f
1309	Massey Ferguson 1525	Iseki	ferguson 1525	2018	25	\N	850	9.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11720.webp	f	\N	f
47	John Deere 60C	Goldini	deere 60c	2005	58	\N	1900	21.3	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10252.webp	t	\N	f
1068	Kubota GL-40	Kubota	GL 40	1991	40	\N	1599	14.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10365.webp	f	\N	f
1069	Kubota GL-43	Kubota	GL 43	1991	43	\N	1599	15.8	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10366.webp	f	\N	f
1070	Kubota GL-46	Kubota	GL 46	1991	46	\N	1700	16.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10367.webp	f	\N	f
1129	Kubota XB-1	Kubota	XB 1	1983	11.8	\N	489	4.3	4x4	Diagonal 7-14	178	658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10906.webp	f	\N	f
1130	Kubota M4063	Kubota	M4063	2018	66	\N	2570	24.2	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10907.webp	f	\N	f
1131	Kubota M4073	Kubota	M4073	2018	74	\N	2570	27.1	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10908.webp	f	\N	f
1136	Kubota M7-133	Kubota	M7 133	2020	130	\N	7350	47.7	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10918.webp	t	\N	f
1137	Kubota M7-163	Kubota	M7 163	2020	150	\N	7350	55	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10919.webp	t	\N	f
1310	Massey Ferguson 1519	Iseki	ferguson 1519	2005	19.5	\N	669	7.2	4x4	Diagonal 29x12.00-15	305	737	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11721.webp	f	\N	f
1311	Massey Ferguson 1740	Iseki	ferguson 1740	2013	38	\N	1528	13.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11722.webp	t	\N	f
1312	Massey Ferguson 1747	Iseki	ferguson 1747	2013	46	\N	1809	16.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11723.webp	f	\N	f
1313	CaseIH 3220	CaseIH	3220	1994	53	\N	2869	15.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1173.webp	f	\N	f
1314	CaseIH 3230	CaseIH	3230	1994	60	\N	2788	19.1	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1174.webp	f	\N	f
64	John Deere 3035D	John Deere	3035D	2000	34.2	\N	1275	11.2	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10315.webp	f	\N	f
65	John Deere 3043D	John Deere	3043D	2000	41.6	\N	1288	13.3	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10316.webp	t	\N	f
1316	CaseIH 3594	CaseIH	3594	1985	182	\N	7978	90.7	4x4	Diagonal 85 - 19	2159	4153	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1176.webp	t	\N	f
1138	Kubota M7-173	Kubota	M7 173	2020	170	\N	7350	62.4	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10920.webp	t	\N	f
1320	CaseIH 4494	CaseIH	4494	1984	213	\N	9453	95.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	43.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1180.webp	t	\N	f
1327	CaseIH 4694	CaseIH	4694	1984	261	\N	10119	109.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	54.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1181.webp	t	\N	f
2967	Fiat 481R	Fiat	481R	1961	40	\N	1640	14.7	4x2	Diagonal 10-36	254	1346	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10933.webp	f	\N	f
2895	CaseIH JXU 75	CaseIH	JXU 75	2008	75.1	\N	4050	27.6	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10950.webp	t	\N	f
143	John Deere 6M 180	John Deere	6M 180	2020	177	\N	8700	51.4	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11748.webp	t	\N	f
144	John Deere 6M 200	John Deere	6M 200	2020	197.1	\N	8700	58.3	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11749.webp	t	\N	f
145	John Deere 6M 220	John Deere	6M 220	2000	217.3	\N	8700	64.9	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11750.webp	t	\N	f
146	John Deere 6M 240	John Deere	6M 240	2000	237.4	\N	8700	71.2	4x4	Radial 480/80R46	480	1936	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11751.webp	t	\N	f
1317	CaseIH 4210	CaseIH	4210	1994	72	\N	3213	32.1	4x4	Diagonal 16.9-28	429	1441	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1177.webp	f	\N	f
1318	CaseIH 4230	CaseIH	4230	1994	84	\N	3033	26.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1178.webp	f	\N	f
1319	CaseIH 4240	CaseIH	4240	1994	104	\N	4604	31.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1179.webp	t	\N	f
149	John Deere 2255	John Deere	2255	1983	50	\N	2320	18.3	4x2	Diagonal 18.4-16.1	467	1203	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td118.webp	f	\N	f
1053	Kubota M8-181	Versatile	m8 181	2000	180	\N	8849	97.7	4x4	Diagonal 8-18	203	803	\N	\N	36	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10332.webp	f	\N	f
2965	Fiat 411C	Fiat	411C	1958	40	\N	2399	22.9	track	Diagonal 58 - 19	1473	2987	\N	\N	10.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10931.webp	f	\N	f
2966	Fiat 451C	Fiat	451C	1958	40	\N	2510	14.7	track	Diagonal 58 - 19	1473	2987	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10932.webp	f	\N	f
2981	Fiat 505C	Fiat	505C	1970	50	\N	2500	18.3	track	Diagonal 70 - 19	1778	3505	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11108.webp	f	\N	f
1315	CaseIH 3394	CaseIH	3394	1985	162	\N	7085	77.5	4x4	Diagonal 85 - 19	2159	4153	\N	\N	40.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1175.webp	t	\N	f
1055	Kubota M4-061	Kubota	M4 061	2000	65.4	\N	2725	19.1	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10334.webp	t	\N	f
1071	Kubota GL-53	Kubota	GL 53	1991	53	\N	1740	19.4	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10368.webp	f	\N	f
1075	Kubota GL-430	Kubota	GL 430	1995	43	\N	1599	15.8	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10371.webp	f	\N	f
2896	CaseIH JXU 85	CaseIH	JXU 85	2008	84.5	\N	4050	31	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10951.webp	t	\N	f
2970	J.I. Case CF 250	Case IH	CF 250	1962	25	\N	1599	9.2	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11015.webp	f	\N	f
2971	J.I. Case CF 350	Case IH	CF 350	1962	35	\N	1700	12.8	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11016.webp	f	\N	f
2972	J.I. Case CF 400	Case IH	CF 400	2000	40	\N	1789	14.7	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11017.webp	f	\N	f
1152	Massey Ferguson 8S.285	Massey Ferguson	ferguson 8s285	2000	281.6	\N	8700	90	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11035.webp	t	\N	f
1153	Massey Ferguson 8S.305	Massey Ferguson	ferguson 8s305	2000	301.7	\N	8700	97.4	4x4	Radial 650/65R42	650	1912	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11036.webp	t	\N	f
1154	Massey Ferguson 7715S	Massey Ferguson	ferguson 7715s	2018	140	\N	6439	59.5	4x4	Radial 460/85R38	460	1747	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11049.webp	t	\N	f
1056	Kubota M4-071	Kubota	M4 071	2000	73.2	\N	2699	22	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10335.webp	t	\N	f
66	John Deere 5090E	John Deere	5090E	2015	90	\N	3299	28.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10345.webp	t	\N	f
1076	Kubota GL-470	Kubota	GL 470	1995	47	\N	1700	17.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10372.webp	f	\N	f
1077	Kubota GL-530	Kubota	GL 530	1995	53	\N	1740	19.4	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10373.webp	f	\N	f
1078	Kubota GL-600	Kubota	GL 600	1995	60	\N	1969	22	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10374.webp	f	\N	f
2975	CaseIH Farmall 110U	CaseIH	Farmall 110U	2000	107	\N	6200	40.4	4x4	Radial 460/85R34	460	1646	\N	\N	21.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11077.webp	t	\N	f
2976	CaseIH Farmall 120U	CaseIH	Farmall 120U	2000	117	\N	6200	40.1	4x4	Radial 460/85R34	460	1646	\N	\N	22.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11078.webp	t	\N	f
3017	CaseIH Magnum 265	CaseIH	magnum 265	2019	265	\N	12972	80	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11832.webp	t	\N	f
3018	CaseIH Magnum 295	CaseIH	magnum 295	2019	295	\N	12972	91	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11833.webp	t	\N	f
3019	CaseIH Magnum 325	CaseIH	magnum 325	2019	325	\N	13063	101.6	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11834.webp	t	\N	f
3020	CaseIH Magnum 355	CaseIH	magnum 355	2019	355	\N	14605	111.2	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11835.webp	t	\N	f
3021	CaseIH Magnum 385	CaseIH	magnum 385	2019	385	\N	14605	117.4	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11836.webp	t	\N	f
155	John Deere 1E 23	John Deere	1E 23	2011	21.5	\N	669	5.9	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11851.webp	f	\N	f
156	John Deere 1M 25	John Deere	1M 25	2013	23.2	\N	726	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11852.webp	f	\N	f
1057	Kubota M1-46	Kubota	M1 46	1988	46	\N	2249	15.6	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10347.webp	f	\N	f
3039	Belarus 420A	Belarus	420A	1983	57	\N	3311	33.1	4x4	Diagonal 13.6-38	345	1552	\N	\N	11.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1425.webp	f	\N	f
3040	Belarus 425A	Belarus	425A	1994	57	\N	3946	18.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1426.webp	f	\N	f
3041	Belarus 500	Belarus	500	1978	65	\N	2766	21.3	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1428.webp	f	\N	f
3067	Belarus 925	Belarus	925	1991	100	\N	4127	33.8	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1454.webp	t	\N	f
3068	Belarus 1025	Belarus	1025	1995	100	\N	4147	33.8	4x4	Diagonal 16.9x38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1455.webp	t	\N	f
3069	Belarus 1500	XTZ	1500	1977	175	\N	8436	85.9	4x4	Diagonal 21.3-24	541	1529	\N	\N	39.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1456.webp	t	\N	f
3070	Belarus 1770	XTZ	1770	1985	185	\N	8883	82	4x4	Diagonal 23.1-26	587	1658	\N	\N	38.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1457.webp	t	\N	f
3072	Belarus 2045	Belarus	2045	1996	22	\N	1230	7	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1459.webp	f	\N	f
1161	Ford 3900	Ford	3900	1975	47	\N	2161	17.2	4x2	Diagonal 11x36	279	1389	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11079.webp	f	\N	f
1349	Massey Ferguson 133 Westland	Massey Ferguson	133 Westland	1972	45	\N	1606	12.3	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11842.webp	f	\N	f
1079	New Holland PowerStar 65	New Holland	holland powerstar 65	2018	64	\N	2830	18.3	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10376.webp	t	\N	f
1080	New Holland PowerStar 75	New Holland	holland powerstar 75	2018	74	\N	2699	23.8	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10377.webp	t	\N	f
1081	New Holland PowerStar 90	New Holland	holland powerstar 90	2018	86	\N	3480	26.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10378.webp	t	\N	f
2979	Belarus 1507	Belarus	1507	2000	165	\N	9200	60.5	4x4	Diagonal 21.3x24	541	1529	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11106.webp	t	\N	f
3074	Belarus 3011	Belarus	3011	1997	36	\N	2007	10.5	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1461.webp	f	\N	f
3075	Belarus 3021	Belarus	3021	1997	36	\N	2041	10.5	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1462.webp	f	\N	f
3084	Belarus 7010	Kirovets	7010	1976	235	\N	13487	78.9	4x4	Diagonal 28.1-26	714	1874	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1477.webp	t	\N	f
3085	Belarus 7100	Belarus	7100	1978	300	\N	13487	137.2	4x4	Diagonal 28.1-26	714	1874	\N	\N	64.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1478.webp	t	\N	f
3086	Belarus 7100M	Belarus	7100M	1990	300	\N	13871	104.9	4x2	Diagonal 30.5-32	775	2130	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1479.webp	t	\N	f
50	John Deere 40A	Goldini	deere 40a	2005	34	\N	1099	10.6	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10255.webp	f	\N	f
3087	Belarus 8011	Belarus	8011	1997	81	\N	3492	31.3	4x2	Diagonal 16.9-38	429	1695	\N	\N	18.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1480.webp	f	\N	f
3089	Belarus 8345	Belarus	8345	1996	81	\N	3919	37.9	4x4	Diagonal 16.9-38	429	1695	\N	\N	18.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1485.webp	f	\N	f
214	John Deere 670	Yanmar	deere 670	1989	19.3	\N	843	5.9	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td149.webp	f	\N	f
3094	Belarus 9345	Belarus	9345	1996	98	\N	3921	36.8	4x4	Diagonal 18.4x38	467	1760	\N	\N	22	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1491.webp	t	\N	f
2982	Fiat 605C Super	Fiat	605C Super	1978	66	\N	3299	24.2	track	Diagonal 78 - 19	1981	3851	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11110.webp	f	\N	f
215	John Deere 770	Yanmar	deere 770	1989	23	\N	954	7.3	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td150.webp	f	\N	f
216	John Deere 870	Yanmar	deere 870	1989	28	\N	1211	9.2	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td151.webp	f	\N	f
217	John Deere 955	John Deere	955	1989	33	\N	902	9.9	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td152.webp	f	\N	f
219	John Deere 970	Yanmar	deere 970	1989	33	\N	1381	11	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td153.webp	f	\N	f
212	John Deere 8960	John Deere	8960	1989	370	\N	15928	153.3	4x4	Diagonal 89 - 19	2261	4326	\N	\N	72.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td147.webp	t	\N	f
213	John Deere 8760	John Deere	8760	1989	300	\N	14558	146.3	4x4	Diagonal 89 - 19	2261	4326	\N	\N	62.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td148.webp	t	\N	f
1058	Kubota M1-55	Kubota	M1 55	1988	55	\N	2449	19.4	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10348.webp	f	\N	f
1059	Kubota M1-65	Kubota	M1 65	1988	65	\N	2580	22.2	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10349.webp	f	\N	f
1061	Kubota M1-75	Kubota	M1 75	1988	75	\N	2950	25.8	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10350.webp	f	\N	f
1062	Kubota M1-85	Kubota	M1 85	1988	85	\N	2980	29.3	4x4	Diagonal 13.9-36	353	1515	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10351.webp	f	\N	f
1082	New Holland PowerStar 100	New Holland	holland powerstar 100	2018	99	\N	3480	31.2	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10379.webp	t	\N	f
1084	New Holland PowerStar 110	New Holland	holland powerstar 110	2018	107	\N	3480	34.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10380.webp	t	\N	f
1085	New Holland PowerStar 120	New Holland	holland powerstar 120	2018	117	\N	3480	36.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10381.webp	t	\N	f
1086	New Holland TS120	New Holland	TS120	1998	118	\N	4740	43.3	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10383.webp	f	\N	f
1087	CaseIH Vestrum 110	CaseIH	vestrum 110	2000	108.5	\N	5851	32.3	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1039.webp	t	\N	f
1093	Massey Ferguson 2405	Massey Ferguson	ferguson 2405	2003	33	\N	1250	12.1	4x4	Diagonal 280/70-18	280	849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10496.webp	f	\N	f
1094	Massey Ferguson 2410	Massey Ferguson	ferguson 2410	2003	40	\N	1300	14.7	4x4	Radial 320/70R20	320	956	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10497.webp	t	\N	f
1095	Massey Ferguson 2415	Massey Ferguson	ferguson 2415	2003	47	\N	1319	17.2	4x4	Radial 12.4R24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10498.webp	t	\N	f
51	John Deere 40R	Goldini	deere 40r	2005	33	\N	1139	10.3	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10260.webp	f	\N	f
60	John Deere 930	John Deere	930	1974	43	\N	2180	12.8	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10295.webp	f	\N	f
1072	Kubota GL-350	Kubota	GL 350	1995	35	\N	1574	12.8	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10369.webp	f	\N	f
1074	Kubota GL-400	Kubota	GL 400	1995	40	\N	1599	14.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10370.webp	f	\N	f
67	John Deere 2240	John Deere	2240	1976	50	\N	1930	24.2	4x2	Diagonal 13.6-28	345	1298	\N	\N	13.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td104.webp	f	\N	f
1088	CaseIH Vestrum 120	CaseIH	vestrum 120	2000	118.4	\N	5851	37.4	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1040.webp	t	\N	f
1089	Massey Ferguson 4445	Massey Ferguson	ferguson 4445	2004	86.5	\N	3680	31.7	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10485.webp	t	\N	f
1090	Massey Ferguson 4455	Massey Ferguson	ferguson 4455	2004	99.9	\N	3680	36.7	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10486.webp	t	\N	f
1096	Massey Ferguson 2430	Massey Ferguson	ferguson 2430	2005	65.7	\N	3050	24.1	4x4	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10499.webp	t	\N	f
68	John Deere 7810	John Deere	7810	1997	175	\N	6414	88.2	4x4	Radial 18.4R38	467	1760	\N	\N	34.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td105.webp	t	\N	f
1097	Massey Ferguson 2435	Massey Ferguson	ferguson 2435	2005	75.1	\N	3050	27.6	4x4	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10500.webp	t	\N	f
1098	Massey Ferguson 2440	Massey Ferguson	ferguson 2440	2005	80.5	\N	3050	29.5	4x4	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10501.webp	t	\N	f
2886	CaseIH Farmall 45C Series II	CaseIH	farmall 45c	2000	45	\N	1710	14	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10570.webp	t	\N	f
72	John Deere 3055	John Deere	3055	1992	105	\N	4395	53.6	4x2	Diagonal 18.4-34	467	1658	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td106.webp	f	\N	f
73	John Deere 3050B	John Deere	3050B	2000	50	\N	1999	15.5	4x4	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10607.webp	f	\N	f
220	John Deere 1070	Yanmar	deere 1070	1989	38.5	\N	1481	12.8	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td154.webp	f	\N	f
222	John Deere 4560	John Deere	4560	1992	155	\N	8438	93.1	4x4	Diagonal 20.8-38	528	1863	\N	\N	32.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td155.webp	t	\N	f
1099	New Holland TK4020	New Holland	TK4020	2009	64.4	\N	3270	23.6	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10508.webp	t	\N	f
230	John Deere 3320	John Deere	3320	2005	32.5	\N	1315	9.2	4x4	Diagonal 41x14-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1557.webp	f	\N	f
1100	New Holland TK4040	New Holland	TK4040	2009	81.2	\N	3989	29.8	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10509.webp	t	\N	f
231	John Deere 3520	John Deere	3520	2005	37	\N	1315	11	4x4	Diagonal 41x14-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1558.webp	t	\N	f
232	John Deere 3720	John Deere	3720	2005	44	\N	1315	16.1	4x4	Diagonal 41x14-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1559.webp	t	\N	f
234	John Deere 4120	John Deere	4120	2004	43.1	\N	1678	12.8	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1560.webp	t	\N	f
71	John Deere 5725	John Deere	5725	2006	89	\N	2686	28.3	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10563.webp	t	\N	f
1104	Kubota B92	Kubota	B92	1999	19.2	\N	699	7	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10574.webp	f	\N	f
82	John Deere 1130	John Deere	1130	1974	53.6	\N	2168	15.7	4x4	Diagonal 16.9x28	429	1441	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10663.webp	f	\N	f
2890	CaseIH CS 110	CaseIH	CS 110	1997	103.6	\N	5015	34	4x4	Radial 600/65R38	600	1745	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10664.webp	t	\N	f
2891	CaseIH CS 120	CaseIH	CS 120	1997	113.4	\N	5244	37.3	4x4	Radial 600/65R38	600	1745	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10665.webp	t	\N	f
2892	CaseIH CS 130	CaseIH	CS 130	1997	123.3	\N	5264	40.5	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10666.webp	t	\N	f
2893	CaseIH CS 150	CaseIH	CS 150	1997	143	\N	5284	47.4	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10667.webp	t	\N	f
85	John Deere 1845F	Goldoni	deere 1845f	1987	55.2	\N	1989	20.3	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10684.webp	f	\N	f
86	John Deere 2345F	Goldoni	deere 2345f	1987	66.1	\N	1989	24.3	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10685.webp	t	\N	f
87	John Deere 2940	John Deere	2940	1980	82	\N	4279	33.8	4x4	Diagonal 16.9-38	429	1695	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td107.webp	f	\N	f
1105	Massey Ferguson GC1723E	Massey Ferguson	ferguson gc1723e	2019	22.5	\N	1220	6.9	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10710.webp	f	\N	f
1106	Massey Ferguson GC1725M	Massey Ferguson	ferguson gc1725m	2019	24.5	\N	1220	7.2	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10711.webp	f	\N	f
1107	Kubota LX2610	Kubota	LX2610	2000	24.8	\N	830	7.2	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10715.webp	f	\N	f
1108	Kubota LX3310	Kubota	LX3310	2000	30.8	\N	939	9.9	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10716.webp	f	\N	f
2954	Fiat 45-76	Fiat	45 76	1990	44.4	\N	1789	16.3	4x4	Diagonal 9.5-28	241	1121	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10789.webp	f	\N	f
237	John Deere 4720	John Deere	4720	2005	58.1	\N	1750	19	4x4	Diagonal 44x18.00-20	457	1118	\N	\N	12.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1563.webp	t	\N	f
238	John Deere 5103	John Deere	5103	2003	50	\N	2282	17	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1564.webp	t	\N	f
88	John Deere 6010SE	John Deere	6010SE	1998	75	\N	3861	27.5	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10776.webp	f	\N	f
89	John Deere 6110SE	John Deere	6110SE	1998	80	\N	3871	29.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10777.webp	t	\N	f
93	John Deere 8450	John Deere	8450	1982	225	\N	12501	118.2	4x4	Diagonal 24.5-32	622	1871	\N	\N	45	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td108.webp	t	\N	f
2959	J.I. Case C	Case IH	C	1929	27	\N	1950	14.6	4x2	Diagonal 42-12	1067	2118	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1081.webp	f	\N	f
2964	Zetor Crystal 170 HD	Zetor	Crystal 170 HD	2016	163.6	\N	5760	51	4x4	Radial 600/65R38	600	1745	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10879.webp	t	\N	f
1162	Kubota B7100HSD	Kubota	B7100HSD	1990	16	\N	570	4.8	4x4	Diagonal 8.3-16	211	765	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11119.webp	f	\N	f
239	John Deere 5203	John Deere	5203	2003	56	\N	2287	17.9	4x4	Diagonal 14.9-28	378	1355	\N	\N	11.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1565.webp	t	\N	f
240	John Deere 5303	John Deere	5303	2003	64	\N	2318	20.7	4x4	Diagonal 16.9-28	429	1441	\N	\N	13.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1566.webp	t	\N	f
241	John Deere 5105	John Deere	5105	2000	45.6	\N	1939	17.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	9.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1567.webp	f	\N	f
242	John Deere 5205	John Deere	5205	2000	53	\N	1939	19.1	4x4	Diagonal 14.9-28	378	1355	\N	\N	11	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1568.webp	f	\N	f
248	John Deere 5225	John Deere	5225	2005	56	\N	2562	17.5	4x4	Diagonal 13.6-28	345	1298	\N	\N	11.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1573.webp	t	\N	f
249	John Deere 5325	John Deere	5325	2005	67	\N	3066	21	4x4	Diagonal 14.9-28	378	1355	\N	\N	13.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1574.webp	t	\N	f
243	John Deere 5220	John Deere	5220	2001	53	\N	2095	16.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1569.webp	f	\N	f
244	John Deere 4960	John Deere	4960	1992	200	\N	8608	105.5	4x4	Diagonal 92 - 19	2337	4455	\N	\N	41.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td157.webp	t	\N	f
245	John Deere 5320	John Deere	5320	2001	64	\N	1746	21.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	12.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1570.webp	t	\N	f
246	John Deere 5420	John Deere	5420	2001	81	\N	1943	24.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1571.webp	f	\N	f
247	John Deere 5520	John Deere	5520	2001	89	\N	2653	30.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	16.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1572.webp	t	\N	f
2897	CaseIH JXU 95	CaseIH	JXU 95	2008	95.2	\N	4249	34.9	4x4	Radial 480/70R34	480	1536	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10952.webp	t	\N	f
2898	CaseIH JXU 105	CaseIH	JXU 105	2008	104.6	\N	4249	38.4	4x4	Radial 480/70R34	480	1536	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10953.webp	t	\N	f
2899	CaseIH JXU 115	CaseIH	JXU 115	2009	111.3	\N	4249	40.8	4x4	Radial 480/70R34	480	1536	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td10954.webp	t	\N	f
1139	Massey Ferguson 6470	Massey Ferguson	ferguson 6470	2008	125	\N	4609	45.9	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10979.webp	t	\N	f
95	John Deere 8850	John Deere	8850	1982	370	\N	17000	157.2	4x4	Diagonal 20.8-42	528	1965	\N	\N	73.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td110.webp	t	\N	f
2902	CaseIH Farmall 50A	CaseIH	Farmall 50A	2010	50	\N	2295	17	4x4	Diagonal 13.6x28	345	1298	\N	\N	14	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td11068.webp	t	\N	f
2903	CaseIH Farmall 60A	CaseIH	Farmall 60A	2010	60	\N	2295	21.8	4x4	Diagonal 13.6x28	345	1298	\N	\N	12.5	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td11069.webp	t	\N	f
2904	CaseIH Farmall 70A	CaseIH	Farmall 70A	2010	70	\N	2295	23.5	4x4	Diagonal 13.6x28	345	1298	\N	\N	16.7	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td11070.webp	t	\N	f
69	John Deere 5425 (2005-2008)	John Deere	5425	2005	81	\N	3059	24.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	17	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1575.webp	t	\N	f
250	John Deere 5525	John Deere	5525	2005	91	\N	3372	28.6	4x4	Radial 420/90R30	420	1518	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1576.webp	t	\N	f
251	John Deere 6403	John Deere	6403	2002	102	\N	3687	32.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	19.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1577.webp	t	\N	f
252	John Deere 6603	John Deere	6603	2002	112	\N	4246	34.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1578.webp	t	\N	f
253	John Deere 6215 (2003-2007)	John Deere	6215	2003	92.5	\N	3687	42.2	4x4	Diagonal 18.4-30	467	1557	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1579.webp	t	\N	f
254	John Deere 5200	John Deere	5200	1992	45.6	\N	2145	23	4x4	Diagonal 13.6-28	345	1298	\N	\N	9.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td158.webp	f	\N	f
257	John Deere 6715	John Deere	6715	2003	129.4	\N	4246	52.3	4x4	Diagonal 18.4-38	467	1760	\N	\N	26.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1582.webp	t	\N	f
258	John Deere 6120	John Deere	6120	2002	80	\N	4241	32.9	4x2	Diagonal 16.9-30	429	1492	\N	\N	16.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1583.webp	t	\N	f
259	John Deere 6220	John Deere	6220	2002	90	\N	3934	36.1	4x2	Diagonal 16.9-30	429	1492	\N	\N	17.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1584.webp	t	\N	f
96	John Deere 1050	Yanmar	deere 1050	1980	37	\N	1425	15.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	8.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td111.webp	t	\N	f
2977	Deutz D 40	Deutz	D 40	1958	34.5	\N	1749	12.7	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11102.webp	f	\N	f
2978	Belarus 255	Belarus	255	2000	25	\N	1928	9.2	4x2	Diagonal 13.50x16	343	989	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11105.webp	f	\N	f
1163	Massey Ferguson 3325	Massey Ferguson	3325	2001	64.4	\N	2150	23.6	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11121.webp	t	\N	f
273	John Deere 8420	John Deere	8420	2002	284	\N	9820	133.3	4x4	Diagonal 02 - 20	51	594	\N	\N	54.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1597.webp	t	\N	f
1164	New Holland Workmaster 25	New Holland	Workmaster 25	2000	24.4	\N	1119	7	4x4	Diagonal 43x16.00	1092	2263	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11129.webp	f	\N	f
276	John Deere 5400	John Deere	5400	1992	68.4	\N	2299	26	4x4	Diagonal 16.9-30	429	1492	\N	\N	13.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td160.webp	t	\N	f
281	John Deere 2120	John Deere	2120	1969	68	\N	3000	22	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1604.webp	f	\N	f
1478	CaseIH DX23	CaseIH	dx23	2005	23	\N	678	6.4	4x4	Diagonal 31x13.5-15	343	787	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1608.webp	f	\N	f
1479	CaseIH DX26	CaseIH	dx26	2005	26	\N	725	7.5	4x4	Diagonal 31x13.5-15	343	787	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1609.webp	f	\N	f
282	John Deere 7600	John Deere	7600	1992	130	\N	6781	63.8	4x4	Diagonal 18.4-38	467	1760	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td161.webp	t	\N	f
1480	CaseIH DX29	CaseIH	DX29	2001	29	\N	1122	8.7	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1610.webp	f	\N	f
1481	CaseIH DX33	CaseIH	DX33	2001	33	\N	1122	9.9	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1611.webp	f	\N	f
1482	CaseIH D35	CaseIH	D35	2001	35	\N	1404	10.9	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1612.webp	f	\N	f
1483	CaseIH DX35	CaseIH	DX35	2001	35	\N	1475	10.7	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1613.webp	f	\N	f
1484	CaseIH D40	CaseIH	D40	2001	40	\N	1359	12.8	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1614.webp	f	\N	f
1485	CaseIH DX40	CaseIH	DX40	2001	40	\N	1509	12.2	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1615.webp	f	\N	f
1486	CaseIH D45	CaseIH	D45	2001	45	\N	1451	14.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1616.webp	f	\N	f
1487	CaseIH DX45	CaseIH	DX45	2001	45	\N	1549	13.9	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1617.webp	f	\N	f
272	John Deere 8320	John Deere	8320	2002	263	\N	9548	112.2	4x4	Diagonal 02 - 20	51	594	\N	\N	49.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1596.webp	t	\N	f
274	John Deere 8520	John Deere	8520	2002	305	\N	10455	158.4	4x4	Diagonal 02 - 20	51	594	\N	\N	60.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1598.webp	t	\N	f
275	John Deere 8120T	John Deere	8120T	2002	208	\N	11770	62.4	track	Diagonal 1-3	25	119	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1599.webp	t	\N	f
277	John Deere 8220T	John Deere	8220T	2002	233	\N	11770	108.9	track	Diagonal 1-3	25	119	\N	\N	44.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1600.webp	t	\N	f
278	John Deere 8320T	John Deere	8320T	2002	263	\N	11770	118.6	track	Diagonal 1-3	25	119	\N	\N	47.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1601.webp	t	\N	f
279	John Deere 8420T	John Deere	8420T	2002	284	\N	11770	121.1	track	Diagonal 1-3	25	119	\N	\N	55.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1602.webp	t	\N	f
280	John Deere 8520T	John Deere	8520T	2002	305	\N	11770	124.4	track	Diagonal 1-3	25	119	\N	\N	60.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1603.webp	t	\N	f
1475	CaseIH Farmall DX18E	CaseIH	Farmall DX18E	2004	18	\N	596	5	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1605.webp	f	\N	f
1488	CaseIH Farmall DX48	CaseIH	Farmall DX48	2004	48	\N	1957	15	4x4	Diagonal 04 - 20	102	681	\N	\N	12.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1618.webp	f	\N	f
1493	CaseIH JX85 Maxxima	Turk Tractor	jx85	2002	70	\N	3172	19.8	4x4	Diagonal 02 - 20	51	594	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1623.webp	f	\N	f
1494	CaseIH JX95 Maxxima	Turk Tractor	jx95	2002	93	\N	3454	18.3	4x4	Diagonal 02 - 20	51	594	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1624.webp	t	\N	f
1495	CaseIH JX1060C	CaseIH	JX1060C	2004	57	\N	2751	17.7	4x4	Diagonal 04 - 20	102	681	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1625.webp	f	\N	f
1496	CaseIH JX1070C	CaseIH	JX1070C	2004	70	\N	2760	22.2	4x4	Diagonal 04 - 20	102	681	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1626.webp	t	\N	f
1497	CaseIH JX1075C	CaseIH	JX1075C	2004	75	\N	3000	23.7	4x4	Diagonal 04 - 20	102	681	\N	\N	15.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1627.webp	t	\N	f
1498	CaseIH JX1075N	CaseIH	JX1075N	2005	75	\N	2522	22.7	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1628.webp	t	\N	f
1499	CaseIH JX1080U	CaseIH	JX1080U	2004	80	\N	3200	42.2	4x4	Diagonal 04 - 20	102	681	\N	\N	18.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1629.webp	f	\N	f
284	John Deere 7800	John Deere	7800	1992	170	\N	6309	84.7	4x4	Diagonal 92 - 19	2337	4455	\N	\N	34.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td163.webp	t	\N	f
1165	New Holland Workmaster 25S	LS	holland workmaster 25s	2000	24.7	\N	654	6.3	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11130.webp	f	\N	f
1166	Massey Ferguson 3307	Massey Ferguson	3307	2021	75	\N	2899	27.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11138.webp	t	\N	f
1167	Massey Ferguson 3308	Massey Ferguson	3308	2021	86	\N	2899	31.6	4x4	Diagonal 16.9x24	429	1339	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11139.webp	t	\N	f
1168	CaseIH C50	CaseIH	C50	1998	53	\N	2765	35.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	10.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1114.webp	f	\N	f
1169	CaseIH CX50	CaseIH	CX50	1998	53	\N	3304	35.5	4x2	Diagonal 14.9-28	378	1355	\N	\N	10.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1115.webp	f	\N	f
1170	Massey Ferguson 650	Massey Ferguson	ferguson 650	2003	138	\N	5426	23.8	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11158.webp	t	\N	f
1171	Massey Ferguson 660	Massey Ferguson	ferguson 660	2003	150	\N	6000	27	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11159.webp	t	\N	f
1172	CaseIH C60	CaseIH	C60	1998	64	\N	2429	40.7	4x2	Diagonal 14.9-28	378	1355	\N	\N	12.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1116.webp	t	\N	f
1173	Massey Ferguson 680	Massey Ferguson	ferguson 680	2003	165	\N	6000	29.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11160.webp	t	\N	f
1174	CaseIH CX60	CaseIH	CX60	1998	64	\N	3304	40.7	4x2	Diagonal 14.9-28	378	1355	\N	\N	12.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1117.webp	t	\N	f
1175	CaseIH C70	CaseIH	C70	1998	73	\N	2694	42.2	4x2	Diagonal 16.9-30	429	1492	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1118.webp	f	\N	f
1508	CaseIH MXU100	CaseIH	MXU100	2004	100	\N	4109	53.6	4x4	Radial 16.9R38	429	1695	\N	\N	20.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1638.webp	t	\N	f
1509	CaseIH MXU110	CaseIH	MXU110	2004	115	\N	4340	54.8	4x4	Radial 16.9R38	429	1695	\N	\N	24.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1639.webp	t	\N	f
285	John Deere 7200	John Deere	7200	1993	92	\N	5750	54.5	4x4	Diagonal 18.4x38	467	1760	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td164.webp	t	\N	f
1510	CaseIH MXU125	CaseIH	MXU125	2004	125	\N	4560	56.8	4x4	Radial 18.4R38	467	1760	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1640.webp	t	\N	f
1511	CaseIH MXU135	CaseIH	MXU135	2004	135	\N	5139	52.3	4x4	Radial 18.4R38	467	1760	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1641.webp	t	\N	f
2986	Fiat 570	Fiat	570	1978	57.2	\N	1900	21	4x2	Diagonal 12-24	305	1128	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11233.webp	f	\N	f
1500	CaseIH JX1090U	CaseIH	JX1090U	2004	90	\N	3400	44.7	4x4	Diagonal 04 - 20	102	681	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1630.webp	t	\N	f
1501	CaseIH JX1100U	CaseIH	JX1100U	2004	98	\N	4125	45	4x4	Diagonal 04 - 20	102	681	\N	\N	21.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1631.webp	t	\N	f
1502	CaseIH MXM120 Maxxum	CaseIH	MXM120 Maxxum	2002	122	\N	5379	54.8	4x4	Diagonal 02 - 20	51	594	\N	\N	24.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1632.webp	t	\N	f
1503	CaseIH MXM130 Maxxum	CaseIH	MXM130 Maxxum	2002	129	\N	5404	41.6	4x4	Diagonal 02 - 20	51	594	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1633.webp	t	\N	f
1504	CaseIH MXM140 Maxxum	CaseIH	MXM140 Maxxum	2002	142	\N	5867	44.4	4x4	Diagonal 02 - 20	51	594	\N	\N	28.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1634.webp	t	\N	f
1505	CaseIH MXM155 Maxxum	CaseIH	MXM155 Maxxum	2002	153	\N	5860	61.9	4x4	Diagonal 02 - 20	51	594	\N	\N	31	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1635.webp	t	\N	f
1506	CaseIH MXM175 Maxxum	CaseIH	MXM175 Maxxum	2002	174	\N	7164	59	4x4	Diagonal 02 - 20	51	594	\N	\N	34.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1636.webp	t	\N	f
1507	CaseIH MXM190 Maxxum	CaseIH	MXM190 Maxxum	2002	190	\N	7924	77.7	4x4	Diagonal 02 - 20	51	594	\N	\N	36.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1637.webp	t	\N	f
1177	Ford FW-35	Waltanna	fw 35	1986	195	\N	9300	61.5	4x4	Diagonal 24.5x32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11187.webp	f	\N	f
1178	CaseIH CX70	CaseIH	CX70	1998	73	\N	3354	42.2	4x2	Diagonal 16.9-30	429	1492	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1119.webp	f	\N	f
97	John Deere 750	Yanmar	deere 750	1981	20	\N	907	7.4	4x4	Diagonal 9.5-24	241	1020	\N	\N	4.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td112.webp	f	\N	f
1179	CaseIH C80	CaseIH	C80	1998	84	\N	2694	42.4	4x2	Diagonal 16.9-30	429	1492	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1120.webp	t	\N	f
1183	New Holland Workmaster 95	New Holland	Workmaster 95	2000	97	\N	3509	28.6	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11207.webp	t	\N	f
1526	Ford 820	Ford	820	1955	40	\N	1292	14.7	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1659.webp	f	\N	f
1527	Ford 950	Ford	950	1954	40	\N	1487	14.7	4x2	Diagonal 12x28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1660.webp	f	\N	f
1528	Ford 541	Ford	541	1958	34	\N	1593	12.5	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1661.webp	f	\N	f
1529	Ford 741	Ford	741	1958	48.4	\N	1542	17.8	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1662.webp	f	\N	f
1530	Ford 771	Ford	771	1958	48.4	\N	1542	17.8	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1663.webp	f	\N	f
1531	Ford 941	Ford	941	1958	62.6	\N	1496	23	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1668.webp	f	\N	f
3098	Zetor 3320	Zetor	3320	1993	46	\N	2869	26.5	4x2	Diagonal 14.9-28	378	1355	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1676.webp	f	\N	f
3099	Zetor 3321	Zetor	3321	1997	46	\N	2821	15.8	4x2	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1677.webp	f	\N	f
3100	Zetor 3340	Zetor	3340	1993	46	\N	3210	26.5	4x4	Diagonal 12.4x36	315	1450	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1678.webp	f	\N	f
3101	Zetor 3341	Zetor	3341	1997	46	\N	3170	15.8	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1679.webp	f	\N	f
3104	Zetor 4320	Zetor	4320	1993	59	\N	2948	28.2	4x2	Diagonal 16.9-28	429	1441	\N	\N	12.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1682.webp	f	\N	f
3106	Zetor 4340	Zetor	4340	1993	59	\N	3388	28.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	12.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1684.webp	f	\N	f
3107	Zetor 4341	Zetor	4341	1997	59	\N	3433	20.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1685.webp	f	\N	f
3110	Zetor 5211	Zetor	5211	1985	45.9	\N	2680	26.5	4x2	Diagonal 12.4-28	315	1247	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1688.webp	f	\N	f
3111	Zetor 5213	Zetor	5213	1991	53.6	\N	1984	15.6	4x2	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1689.webp	t	\N	f
3112	Zetor 5243	Zetor	5243	1991	53.6	\N	2180	15.6	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1690.webp	t	\N	f
3113	Zetor 5245	Zetor	5245	1985	45.9	\N	3079	26.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1691.webp	f	\N	f
3114	Zetor 6211	Zetor	6211	1986	61	\N	2943	28.2	4x2	Diagonal 14-30	356	1367	\N	\N	12.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1692.webp	f	\N	f
1519	CaseIH STX425	CaseIH	STX425	2002	425	\N	23133	135.7	4x4	Diagonal 02 - 20	51	594	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1649.webp	t	\N	f
286	John Deere 7400	John Deere	7400	1993	100	\N	5745	56.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	21.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td165.webp	t	\N	f
3109	Zetor 5011	Zetor	5011	1980	49.6	\N	2429	15.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1687.webp	f	\N	f
290	John Deere 8570	John Deere	8570	1993	250	\N	14560	142	4x4	Diagonal 93 - 19	2362	4498	\N	\N	45	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td169.webp	t	\N	f
1184	New Holland Workmaster 105	New Holland	Workmaster 105	2000	112	\N	3509	33.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11208.webp	t	\N	f
1185	New Holland Workmaster 120	New Holland	Workmaster 120	2000	120	\N	3509	36.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11209.webp	t	\N	f
1186	CaseIH CX80	CaseIH	CX80	1998	84	\N	3354	42.4	4x2	Diagonal 16.9-30	429	1492	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1121.webp	t	\N	f
2983	CaseIH Luxxum 100	CaseIH	Luxxum 100	2016	99	\N	4389	36.3	4x4	Radial 540/65R38	540	1667	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11211.webp	t	\N	f
2984	CaseIH Luxxum 110	CaseIH	Luxxum 110	2016	107	\N	4389	39.3	4x4	Radial 540/65R38	540	1667	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11212.webp	t	\N	f
2985	CaseIH Luxxum 120	CaseIH	Luxxum 120	2016	117	\N	4389	42.9	4x4	Radial 540/65R38	540	1667	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11213.webp	t	\N	f
1189	Massey Ferguson 352	Massey Ferguson	352	1993	59.9	\N	2639	18.1	4x4	Radial 14.9R28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11218.webp	t	\N	f
1190	CaseIH MX80C	CaseIH	MX80C	1998	84	\N	4500	49.3	4x4	Diagonal 16.9-34	429	1593	\N	\N	17	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1122.webp	t	\N	f
1191	CaseIH C90	CaseIH	C90	1998	90	\N	2704	41	4x2	Diagonal 16.9-30	429	1492	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1123.webp	t	\N	f
98	John Deere 6135R	John Deere	6135R	2016	135.4	\N	6400	43.7	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11236.webp	t	\N	f
1192	CaseIH CX90	CaseIH	CX90	1998	90	\N	3354	41	4x2	Diagonal 16.9-30	429	1492	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1124.webp	t	\N	f
3115	Zetor 6245	Zetor	6245	1985	61	\N	3390	28.2	4x4	Diagonal 11-36	279	1389	\N	\N	12.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1693.webp	f	\N	f
3116	Zetor 6320	Zetor	6320	1993	66	\N	3039	33.3	4x2	Diagonal 16.9-34	429	1593	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1694.webp	f	\N	f
3118	Zetor 6340	Zetor	6340	1993	66	\N	3583	33.3	4x4	Diagonal 16.9-34	429	1593	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1696.webp	f	\N	f
3119	Zetor 6341	Zetor	6341	1997	66	\N	3538	22.7	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1697.webp	f	\N	f
3120	Zetor 7211	Zetor	7211	1985	64.6	\N	2903	21.3	4x2	Diagonal 16.9-28	429	1441	\N	\N	13.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1698.webp	f	\N	f
1187	Massey Ferguson 340	Massey Ferguson	340	1988	46	\N	3928	15	4x4	Diagonal 13-24	330	1171	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11210.webp	f	\N	f
1188	Massey Ferguson 342	Massey Ferguson	342	1993	42	\N	2500	15.4	4x4	Diagonal 93 - 19	2362	4498	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11217.webp	f	\N	f
109	John Deere 6R 230	John Deere	6R 230	2000	226.6	\N	9300	76.7	4x4	Radial 520/85R42	520	1951	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11247.webp	t	\N	f
110	John Deere 6R 250	John Deere	6R 250	2000	246.8	\N	9648	84	4x4	Radial 520/85R42	520	1951	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11248.webp	t	\N	f
1193	CaseIH MX90C	CaseIH	MX90C	1998	90	\N	4750	53.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1125.webp	t	\N	f
1194	CaseIH C100	CaseIH	C100	1998	100	\N	2704	40.7	4x2	Diagonal 16.9-30	429	1492	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1126.webp	t	\N	f
1195	CaseIH CX100	CaseIH	CX100	1998	100	\N	3354	40.7	4x2	Diagonal 16.9-34	429	1593	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1127.webp	t	\N	f
1196	Massey Ferguson 6S.135	Massey Ferguson	ferguson 6s135	2017	134.1	\N	5800	49.2	4x4	Radial 520/85R38	520	1849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11278.webp	t	\N	f
3124	Zetor 7340	Zetor	7340	1995	78	\N	3628	26.8	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1702.webp	t	\N	f
3125	Zetor 7341	Zetor	7341	1997	78	\N	3610	44	4x4	Radial 18.4R34	467	1658	\N	\N	16.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1703.webp	t	\N	f
3126	Zetor 7711	Zetor	7711	1986	81	\N	3129	33.3	4x2	Diagonal 16.9-28	429	1441	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1704.webp	t	\N	f
3127	Zetor 7745	Zetor	7745	1988	81	\N	3583	33.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1705.webp	t	\N	f
3130	Zetor 8111	Zetor	8111	1985	70	\N	3946	25.7	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1708.webp	f	\N	f
3131	Zetor 8145	Zetor	8145	1985	70	\N	4263	25.7	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1709.webp	f	\N	f
292	John Deere 8870	John Deere	8870	1993	350	\N	14260	155.8	4x4	Diagonal 30.5-32	775	2130	\N	\N	67.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td171.webp	t	\N	f
3133	Zetor 8245	Zetor	8245	1990	80	\N	4340	26.4	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1711.webp	f	\N	f
3134	Zetor 8520	Zetor	8520	1995	80	\N	3375	27.9	4x2	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1712.webp	t	\N	f
2987	Fiat 55-88	Fiat	55 88	1990	54.3	\N	3099	17.6	4x4	Diagonal 11-36	279	1389	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11252.webp	f	\N	f
2988	Fiat 60-88	Fiat	60 88	1990	59.2	\N	3200	19.7	4x4	Diagonal 12-36	305	1433	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11253.webp	f	\N	f
2990	Fiat 70-88	Fiat	70 88	1990	69	\N	3200	25.3	4x4	Diagonal 90 - 19	2286	4369	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11255.webp	f	\N	f
3128	Zetor 8011	Zetor	8011	1968	85	\N	3700	31.2	4x2	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1706.webp	f	\N	f
3129	Zetor 8045	Zetor	8045	1968	85	\N	4149	31.2	4x4	Diagonal 12-36	305	1433	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1707.webp	f	\N	f
1197	Massey Ferguson 6S.145	Massey Ferguson	ferguson 6s145	2017	143.5	\N	5800	52.6	4x4	Radial 520/85R38	520	1849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11279.webp	t	\N	f
1198	CaseIH MX100 Maxxum	CaseIH	MX100 Maxxum	1997	100	\N	5651	31.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1128.webp	t	\N	f
1199	Massey Ferguson 6S.155	Massey Ferguson	ferguson 6s155	2017	152.9	\N	6300	56.1	4x4	Radial 520/85R38	520	1849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11280.webp	t	\N	f
1200	Massey Ferguson 6S.165	Massey Ferguson	ferguson 6s165	2017	162.3	\N	6300	59.5	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11281.webp	t	\N	f
1201	Massey Ferguson 6S.180	Massey Ferguson	ferguson 6s180	2017	177	\N	6300	64.9	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11282.webp	t	\N	f
1205	Massey Ferguson 7S.190	Massey Ferguson	ferguson 7s190	2000	187.7	\N	6300	68.9	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11286.webp	t	\N	f
1206	Massey Ferguson 7S.210	Massey Ferguson	ferguson 7s210	2000	206.5	\N	6300	75.8	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11287.webp	t	\N	f
111	John Deere 650	Yanmar	deere 650	1981	17	\N	743	5.3	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td113.webp	f	\N	f
3135	Zetor 8540	Zetor	8540	1995	80	\N	3717	27.9	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1713.webp	t	\N	f
3136	Zetor 8620	Zetor	8620	1996	82	\N	3370	27.1	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1714.webp	f	\N	f
3137	Zetor 8640	Zetor	8640	1996	82	\N	3823	27.1	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1715.webp	f	\N	f
3138	Zetor 9520	Zetor	9520	1991	93	\N	3406	31.6	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1716.webp	t	\N	f
3139	Zetor 9540	Zetor	9540	1991	93	\N	3822	31.6	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1717.webp	t	\N	f
3140	Zetor 9620	Zetor	9620	1996	92	\N	3370	30.5	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1718.webp	t	\N	f
3141	Zetor 9640	Zetor	9640	1996	92	\N	3823	30.5	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1719.webp	t	\N	f
293	John Deere 8970	John Deere	8970	1993	400	\N	14460	152.6	4x4	Diagonal 30.5-32	775	2130	\N	\N	78.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td172.webp	t	\N	f
3142	Zetor 10011	Zetor	10011	1978	100	\N	3800	32.5	4x2	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1720.webp	t	\N	f
3143	Zetor 10045	Zetor	10045	1978	100	\N	4240	36.7	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1721.webp	t	\N	f
3145	Zetor 10145	Zetor	10145	1985	88	\N	4320	32.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1723.webp	t	\N	f
3147	Zetor 10245	Zetor	10245	1990	88	\N	4309	32.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1725.webp	t	\N	f
3148	Zetor 10540	Zetor	10540	1995	105	\N	4127	34.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1726.webp	t	\N	f
3150	Zetor 12045	Zetor	12045	1974	120	\N	4790	41.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1728.webp	f	\N	f
3151	Zetor 12145	Zetor	12145	1983	102.2	\N	4808	37.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1729.webp	f	\N	f
2992	Fiat 955C	Fiat	955C	1981	88	\N	5919	32.3	track	Diagonal 81 - 19	2057	3980	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11288.webp	f	\N	f
2993	Fiat 805C	Fiat	805C	1975	79.1	\N	5150	29	track	Diagonal 75 - 19	1905	3721	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11289.webp	f	\N	f
1207	CaseIH MX100C	CaseIH	MX100C	1998	100	\N	4750	30.5	4x4	Diagonal 98 - 20	2489	4740	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1129.webp	t	\N	f
1208	CaseIH MX110 Maxxum	CaseIH	MX110 Maxxum	1997	110	\N	5651	34.9	4x4	Diagonal 97 - 19	2464	4671	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1130.webp	t	\N	f
3149	Zetor 12011	Zetor	12011	1974	120	\N	4100	44	4x2	Diagonal 18.4-15	467	1176	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1727.webp	f	\N	f
1210	Ford 840	Ford	840	1957	40	\N	1292	14.7	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11306.webp	f	\N	f
112	John Deere 9R 390	John Deere	9R 390	2015	384.9	\N	20856	122.9	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11307.webp	t	\N	f
113	John Deere 9R 440	John Deere	9R 440	2015	434.5	\N	20856	122.9	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11308.webp	t	\N	f
114	John Deere 9R 490	John Deere	9R 490	2015	482.8	\N	20856	122.9	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11309.webp	t	\N	f
115	John Deere 9R 540	John Deere	9R 540	2015	532.4	\N	20856	122.9	4x4	Radial 800/70R38	800	2085	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11310.webp	t	\N	f
116	John Deere 9R 590	John Deere	9R 590	2015	582	\N	20856	122.9	4x4	Radial 800/70R38	800	2085	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11311.webp	t	\N	f
117	John Deere 9R 640	John Deere	9R 640	2015	631.6	\N	21174	122.9	4x4	Radial 800/70R38	800	2085	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11312.webp	t	\N	f
294	John Deere 8020	John Deere	8020	1961	215	\N	8935	78.9	4x4	Diagonal 18.00x25	457	1412	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td173.webp	f	\N	f
3153	Zetor 12245	Zetor	12245	1990	120	\N	4819	38.5	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1731.webp	f	\N	f
3154	Zetor 16045	Zetor	16045	1978	160	\N	5009	58.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1733.webp	t	\N	f
3155	Zetor 16145	Zetor	16145	1985	161	\N	5069	49.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1734.webp	t	\N	f
3157	Zetor 25	Zetor	25	1946	25	\N	1749	9.2	4x2	Diagonal 11.25-24	286	1095	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1736.webp	f	\N	f
3158	Zetor 15	Zetor	15	1947	15	\N	1399	5.5	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1737.webp	f	\N	f
3159	Zetor 25A	Zetor	25A	1949	25	\N	1826	9.2	4x2	Diagonal 11.25-24	286	1095	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1738.webp	f	\N	f
3160	Zetor 25K	Zetor	25K	1948	25	\N	1955	9.2	4x2	Diagonal 9-36	229	1303	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1739.webp	f	\N	f
295	John Deere 2210	John Deere	2210	2003	23	\N	254	6.5	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td174.webp	f	\N	f
3162	Zetor 50 Super	Zetor	50 Super	1960	50	\N	2550	18.3	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1741.webp	f	\N	f
3164	Zetor 2011	Zetor	2011	1963	25	\N	1300	9.2	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1743.webp	f	\N	f
3167	Zetor 3011	Zetor	3011	1960	39	\N	1480	14.3	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1746.webp	f	\N	f
296	John Deere 3640	John Deere	3640	1984	117	\N	4791	42.9	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td175.webp	f	\N	f
3172	Zetor 4011	Zetor	4011	1962	53	\N	1964	19.4	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1751.webp	f	\N	f
3174	Zetor 2511	Zetor	2511	1968	25	\N	1339	9.2	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1753.webp	f	\N	f
1209	Massey Ferguson 152S	Massey Ferguson	152S	2000	47	\N	1754	16.4	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11305.webp	f	\N	f
1211	CaseIH MX120 Maxxum	CaseIH	MX120 Maxxum	1997	120	\N	5651	38.5	4x4	Diagonal 97 - 20	2464	4696	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1131.webp	t	\N	f
3166	Zetor 2023	Zetor	2023	1963	25	\N	1300	9.2	track	Diagonal 63 - 19	1600	3203	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1745.webp	f	\N	f
3171	Zetor 3045	Zetor	3045	1960	39	\N	1480	14.3	4x4	Diagonal 60 - 19	1524	3073	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1750.webp	f	\N	f
3173	Zetor 4016	Zetor	4016	1962	53	\N	1964	19.4	track	Diagonal 62 - 19	1575	3160	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1752.webp	f	\N	f
1212	Massey Ferguson 152V	Massey Ferguson	152V	2000	50.3	\N	1700	18.5	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11317.webp	f	\N	f
3199	Zetor 10741	Zetor	10741	2004	101	\N	4309	35.1	4x4	Diagonal 04 - 20	102	681	\N	\N	22.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1778.webp	t	\N	f
122	John Deere 5050E	John Deere	5050E	2015	50.1	\N	2634	13.9	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11319.webp	t	\N	f
299	John Deere 4700	John Deere	4700	2000	48	\N	258	15.2	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1793.webp	f	\N	f
3175	Zetor 3511	Zetor	3511	1968	39	\N	1520	13	4x2	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1754.webp	f	\N	f
3176	Zetor 3545	Zetor	3545	1968	39	\N	1520	13	4x2	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1755.webp	f	\N	f
3178	Zetor 5511	Zetor	5511	1968	56	\N	2245	19.8	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1757.webp	f	\N	f
3179	Zetor 5545	Zetor	5545	1968	56	\N	2550	19.8	4x4	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1758.webp	f	\N	f
3182	Zetor 4712	Zetor	4712	1972	45	\N	2049	15.4	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1761.webp	f	\N	f
3184	Zetor 5711	Zetor	5711	1972	58	\N	2540	17.8	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1763.webp	f	\N	f
3185	Zetor 5718	Zetor	5718	1972	54.3	\N	2839	19.8	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1764.webp	f	\N	f
3186	Zetor 5745	Zetor	5745	1972	58	\N	2621	19.8	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1765.webp	f	\N	f
3187	Zetor 5748	Zetor	5748	1972	58	\N	3172	19.8	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1766.webp	f	\N	f
3188	Zetor 6711	Zetor	6711	1972	65	\N	2619	22	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1767.webp	f	\N	f
3189	Zetor 6718	Zetor	6718	1972	65	\N	2835	22	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1768.webp	f	\N	f
3190	Zetor 6745	Zetor	6745	1972	65	\N	3036	22	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1769.webp	f	\N	f
3191	Zetor 6748	Zetor	6748	1972	65	\N	3246	22	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1770.webp	f	\N	f
3193	Zetor Proxima 6441	Zetor	Proxima 6441	2004	67	\N	3601	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1772.webp	t	\N	f
3197	Zetor Proxima 8441	Zetor	Proxima 8441	2004	90	\N	3701	28.6	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1776.webp	t	\N	f
3198	Zetor 9741	Zetor	9741	2004	90	\N	4127	29.7	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1777.webp	t	\N	f
297	John Deere 4710	John Deere	4710	2002	46.3	\N	1564	14.1	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1782.webp	f	\N	f
3200	J.I. Case CC	Case IH	CC	1929	27	\N	1859	13.1	4x2	Diagonal 48x8	1219	2276	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1800.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1107/	f
3201	J.I. Case 210-B	Case IH	210 B	1958	30	\N	1298	11	4x2	Diagonal 10-24	254	1041	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1804.webp	f	\N	f
1213	Massey Ferguson 145V	Massey Ferguson	145V	2000	44.25	\N	1692	13.8	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11318.webp	f	\N	f
1214	CaseIH MX135 Maxxum	CaseIH	MX135 Maxxum	1997	135	\N	5651	42.2	4x4	Diagonal 97 - 20	2464	4696	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1132.webp	t	\N	f
3180	Zetor 5516	Zetor	5516	1968	60	\N	2439	22	track	Diagonal 68 - 19	1727	3419	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1759.webp	f	\N	f
123	John Deere 5060E	John Deere	5060E	2015	60.5	\N	2684	17.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11320.webp	t	\N	f
124	John Deere 5067E	John Deere	5067E	2015	67.5	\N	2734	20.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11321.webp	t	\N	f
305	Massey Ferguson 491	Massey Ferguson	ferguson 491	2004	89	\N	3299	31.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1824.webp	t	\N	f
306	Massey Ferguson 492	Massey Ferguson	ferguson 492	2004	99	\N	3299	33.6	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1825.webp	t	\N	f
1535	Kubota L3940	Kubota	L3940	2007	40.5	\N	1579	12.1	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1833.webp	f	\N	f
1536	Kubota L4240	Kubota	L4240	2007	44	\N	1599	13.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1834.webp	f	\N	f
1537	Kubota L4740	Kubota	L4740	2007	49	\N	1701	15.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1835.webp	f	\N	f
1538	Kubota L5040	Kubota	L5040	2007	52	\N	1725	16.1	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1836.webp	t	\N	f
1539	Kubota L5240	Kubota	L5240	2013	54	\N	1769	16.5	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1837.webp	t	\N	f
1540	Kubota L5740	Kubota	L5740	2000	59	\N	1769	18.3	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1838.webp	t	\N	f
1541	Kubota M95S	Kubota	M95S	2005	95	\N	2839	30.8	4x2	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1839.webp	t	\N	f
1544	Kubota M125X	Kubota	M125X	2005	125	\N	4390	37.8	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1842.webp	t	\N	f
1545	Kubota M8540	Kubota	M8540	2007	84.6	\N	2449	27.5	4x4	Diagonal 18.4-28	467	1506	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1843.webp	t	\N	f
1546	Kubota M9540	Kubota	M9540	2006	95	\N	2499	30.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1844.webp	t	\N	f
1547	Kubota M5040	Kubota	M5040	2007	50.5	\N	1799	16.5	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1845.webp	f	\N	f
1548	Kubota M6040	Kubota	M6040	2007	63.5	\N	2170	20.5	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1846.webp	t	\N	f
3203	Zetor Forterra 10641	Zetor	Forterra 10641	1999	105	\N	4309	35.1	4x4	Diagonal 99 - 20	2515	4783	\N	\N	22	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1890.webp	t	\N	f
1550	Kubota M4800SU	Kubota	M4800SU	2004	50	\N	1699	15.8	4x2	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1848.webp	f	\N	f
1551	Kubota MX5000	Kubota	MX5000	2002	52.2	\N	1489	16.1	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1849.webp	f	\N	f
1552	Kubota L3130	Kubota	L3130	2003	32.1	\N	1499	9.4	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1850.webp	f	\N	f
1553	Kubota L3430	Kubota	L3430	2003	35.1	\N	1499	10.5	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1851.webp	f	\N	f
1554	Kubota L3830	Kubota	L3830	2003	39	\N	1515	11.7	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1852.webp	f	\N	f
1555	Kubota L4330	Kubota	L4330	2003	43.2	\N	1560	13.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1853.webp	f	\N	f
1556	Kubota L4630	Kubota	L4630	2003	47.2	\N	1560	14.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1854.webp	f	\N	f
1557	Kubota L5030	Kubota	L5030	2003	52.2	\N	1680	16.8	4x4	Diagonal 14.9-26	378	1304	\N	\N	12.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1855.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1369/	f
1558	Kubota L2800	Kubota	L2800	2004	29	\N	1150	8.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1856.webp	f	\N	f
1561	Kubota B7410	Kubota	B7410	2004	18	\N	600	5.5	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1859.webp	f	\N	f
1562	Kubota B7510	Kubota	B7510	2004	21	\N	600	6.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1860.webp	f	\N	f
1564	Kubota B2630	Kubota	B2630	2006	26	\N	810	7.2	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1862.webp	f	\N	f
307	John Deere 5210	John Deere	5210	1998	53	\N	2109	16.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1885.webp	f	\N	f
308	John Deere 5310	John Deere	5310	1998	64	\N	1973	21.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	12.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1886.webp	t	\N	f
309	John Deere 5410	John Deere	5410	1998	81	\N	2494	24.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1887.webp	f	\N	f
310	John Deere 5510	John Deere	5510	1998	89	\N	2594	30.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	16.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1888.webp	t	\N	f
311	John Deere 6110	John Deere	6110	1999	84	\N	3590	21.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1889.webp	t	\N	f
1543	Kubota M108X	Kubota	M108X	2007	108	\N	2800	34.1	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://dieselkubota.com.co/wp-content/uploads/2017/03/southmaq-tractor-frutero-tract-1.png	f	https://dieselkubota.com.co/productos/tractor-kubota-m108-colombia/	t
1216	Massey Ferguson 174-4	Landini	ferguson 174 4	1973	65	\N	2490	23.8	4x4	Diagonal 13-30	330	1323	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11333.webp	f	\N	f
1217	Massey Ferguson 174C	Massey Ferguson	174C	2000	61	\N	3339	22.4	track	Diagonal 74-4	1880	3297	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11334.webp	f	\N	f
1218	CaseIH MX170 Maxxum	CaseIH	MX170 Maxxum	1998	145	\N	6395	53.2	4x4	Diagonal 98 - 20	2489	4740	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1134.webp	t	\N	f
1411	Kubota B4200	Kubota	B4200	1987	12.5	\N	420	3.7	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1265.webp	f	\N	f
3210	Fiat 350	Fiat	350	1968	35	\N	1559	12.8	4x4	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1973.webp	f	\N	f
3204	Fiat 215	Fiat	215	1965	22	\N	1099	8.1	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1967.webp	f	\N	f
3205	Fiat 315	Fiat	315	1965	33	\N	1920	12.1	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1968.webp	f	\N	f
3206	Fiat 415	Fiat	415	1965	44	\N	1840	16.1	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1969.webp	f	\N	f
3207	Fiat 615	Fiat	615	1965	66	\N	3160	19.8	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1970.webp	f	\N	f
3208	Fiat 250	Fiat	250	1968	25	\N	1394	9.2	4x4	Diagonal 10-24	254	1041	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1971.webp	f	\N	f
3209	Fiat 300	Fiat	300	1971	28	\N	1219	10.3	4x4	Diagonal 8.00-20	203	853	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1972.webp	f	\N	f
3211	Fiat 400	Fiat	400	1968	38	\N	2145	13.9	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1974.webp	f	\N	f
3213	Fiat 480	Fiat	480	1973	48	\N	2619	17.6	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1976.webp	f	\N	f
3215	Fiat 540	Fiat	540	1973	54	\N	2350	19.8	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1978.webp	f	\N	f
3216	Fiat 550	Fiat	550	1968	55	\N	2440	20.2	4x4	Diagonal 11-36	279	1389	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1979.webp	f	\N	f
12	Fiat 640	Fiat	640	1973	64	\N	2800	22.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td1981.webp	f	\N	f
3217	Fiat 650	Fiat	650	1969	65	\N	2874	23.8	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1982.webp	f	\N	f
3219	Fiat 750	Fiat	750	1967	75	\N	3020	27.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1984.webp	f	\N	f
3223	Fiat 900	Fiat	900	1969	90	\N	4180	33	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1988.webp	f	\N	f
3226	Fiat 1300	Fiat	1300	1973	130	\N	5300	42.2	4x2	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1991.webp	f	\N	f
3228	Fiat 780	Fiat	780	1975	78	\N	3200	28.6	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1993.webp	f	\N	f
3229	Fiat 880	Fiat	880	1975	88	\N	3220	32.3	4x2	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1994.webp	f	\N	f
3232	Fiat 880/5	Fiat	880/5	1980	88	\N	3444	47.1	4x4	Diagonal 16.9-38	429	1695	\N	\N	19.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1997.webp	f	\N	f
3235	Fiat 1280	Fiat	1280	1979	123	\N	5930	40	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2000.webp	t	\N	f
1215	CaseIH MX150 Maxxum	CaseIH	MX150 Maxxum	1998	130	\N	6350	47.7	4x4	Diagonal 98 - 20	2489	4740	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1133.webp	t	\N	f
3238	Fiat 1880	Fiat	1880	1979	180	\N	6551	59.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2003.webp	t	\N	f
3239	Fiat 44-23	Versatile	44 23	1979	230	\N	11902	84.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2004.webp	t	\N	f
3212	Fiat 450	Fiat	450	1968	45	\N	2195	13.2	4x4	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1975.webp	f	\N	f
3012	Fiat 600 (1971-1973)	Fiat	600	1971	60	\N	2330	22	4x4	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1980.webp	f	\N	f
3218	Fiat 650S Special	Fiat	650S Special	1971	70	\N	3250	25.7	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1983.webp	f	\N	f
3220	Fiat 750S Special	Fiat	750S Special	1971	80	\N	3369	29.4	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1985.webp	f	\N	f
3221	Fiat 850	Fiat	850	1969	85	\N	3659	31.2	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1986.webp	f	\N	f
3224	Fiat 1000	Fiat	1000	1972	100	\N	3820	36.7	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1989.webp	f	\N	f
3225	Fiat 1000 Super	Fiat	1000 Super	1976	108.5	\N	3850	39.8	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1990.webp	f	\N	f
3227	Fiat 1300 Super	Fiat	1300 Super	1976	150	\N	5200	55	4x2	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1992.webp	f	\N	f
3230	Fiat 580	Fiat	580	1978	57.2	\N	2615	18.3	4x4	Diagonal 11-36	279	1389	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1995.webp	f	\N	f
3231	Fiat 680	Fiat	680	1978	68	\N	2800	24.9	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1996.webp	f	\N	f
3233	Fiat 980	Fiat	980	1979	98	\N	3759	36	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1998.webp	f	\N	f
3234	Fiat 1180	Fiat	1180	1979	115	\N	4850	38.5	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1999.webp	f	\N	f
3237	Fiat 1580	Fiat	1580	1979	160	\N	6451	58.7	4x4	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2002.webp	t	\N	f
1219	CaseIH MX180 Magnum	CaseIH	MX180 Magnum	1999	145	\N	8436	86.7	4x4	Radial 18.4R42	467	1861	\N	\N	40.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1135.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1222/	f
1220	CaseIH MX200 Magnum	CaseIH	MX200 Magnum	1999	165	\N	8935	88.3	4x4	Radial 18.4R46	467	1963	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1136.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1223/	f
1221	CaseIH MX220 Magnum	CaseIH	MX220 Magnum	1999	185	\N	8935	92	4x4	Radial 18.4R46	467	1963	\N	\N	40.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1137.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1225/	f
1222	CaseIH 234	Mitsubishi	234	1985	15.2	\N	635	5.6	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1138.webp	f	\N	f
1223	CaseIH 235	Mitsubishi	235	1986	18	\N	612	5.6	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1139.webp	f	\N	f
1224	Kubota L2502	Kubota	L2502	2014	24.8	\N	1275	7.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11394.webp	f	\N	f
2927	Fiat 50-66S	Fiat	50 66S	1992	49.4	\N	2375	18.1	4x4	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10017.webp	f	\N	f
2928	Fiat 56-66S	Fiat	56 66S	1992	54.3	\N	2375	19.9	4x4	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10018.webp	f	\N	f
2929	Fiat 60-66S	Fiat	60 66S	1992	59.1	\N	2490	21.7	4x4	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10019.webp	f	\N	f
2930	Fiat 65-66S	Fiat	65 66S	1992	64.3	\N	2560	23.6	4x4	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10020.webp	f	\N	f
2931	Fiat 70-66S	Fiat	70 66S	1992	69.1	\N	2790	25.4	4x4	Diagonal 12-36	305	1433	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10021.webp	f	\N	f
2932	Fiat 80-66S	Fiat	80 66S	1992	78.9	\N	2960	28.9	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td10022.webp	f	\N	f
1030	Kubota STW37	Kubota	STW37	2006	36.6	\N	1104	9.4	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10140.webp	f	\N	f
1031	Kubota STW40	Kubota	STW40	2000	38.5	\N	1104	10.1	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td10141.webp	f	\N	f
30	John Deere 25C	John Deere	25C	2009	23.7	\N	1399	6.5	4x2	Diagonal 8.25x16	210	763	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10223.webp	f	\N	f
31	John Deere 3036E	John Deere	3036E	2009	36.6	\N	1999	13.4	4x4	Diagonal 41x14-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td10224.webp	t	\N	f
2900	CaseIH Farmall 35A Series II	CaseIH	farmall 35a	2017	35	\N	1391	10.9	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td11066.webp	t	\N	f
2901	CaseIH Farmall 40A Series II	CaseIH	farmall 40a	2017	40	\N	1391	12.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td11067.webp	t	\N	f
1202	Massey Ferguson 7S.155	Massey Ferguson	ferguson 7s155	2000	152.9	\N	5800	56.1	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11283.webp	t	\N	f
1203	Massey Ferguson 7S.165	Massey Ferguson	ferguson 7s165	2000	162.3	\N	5800	59.5	4x4	Radial 520/85R38	520	1849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11284.webp	t	\N	f
1204	Massey Ferguson 7S.180	Massey Ferguson	ferguson 7s180	2000	177	\N	6300	64.9	4x4	Radial 580/70R38	580	1777	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11285.webp	t	\N	f
1244	Massey Ferguson 4292	Massey Ferguson	ferguson 4292	2010	110	\N	6720	36.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11475.webp	t	\N	f
1245	Massey Ferguson 4297	Massey Ferguson	ferguson 4297	2010	120	\N	6745	44	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11476.webp	t	\N	f
1246	Massey Ferguson 4299	Massey Ferguson	ferguson 4299	2010	130	\N	7040	47.7	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11477.webp	t	\N	f
1250	Massey Ferguson 4315	Massey Ferguson	ferguson 4315	2001	53	\N	2634	19.4	4x4	Radial 12.4R32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11502.webp	f	\N	f
1306	Massey Ferguson 1765M	Massey Ferguson	ferguson 1765m	2000	67	\N	1799	24.6	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11718.webp	t	\N	f
3022	CaseIH Magnum 405	CaseIH	magnum 405	2019	405	\N	14605	129.1	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td11837.webp	t	\N	f
1338	CaseIH 4894	CaseIH	4894	1984	300	\N	11680	122.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	58.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1182.webp	t	\N	f
233	John Deere 4760	John Deere	4760	1992	175	\N	8483	95.5	4x4	Diagonal 92 - 19	2337	4455	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td156.webp	t	\N	f
1341	Kubota L3770	Kubota	L3770	2013	37	\N	1690	10.3	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11822.webp	f	\N	f
3095	J.I. Case 610-B	Case IH	610 B	1958	45	\N	1818	16.5	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1548.webp	f	\N	f
221	John Deere 990	John Deere	990	2000	40.4	\N	1440	12.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1549.webp	f	\N	f
150	John Deere 5600	John Deere	5600	1996	75	\N	3519	23.5	4x4	Diagonal 96 - 19	2438	4628	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11828.webp	f	\N	f
1342	Kubota L4270	Kubota	L4270	2013	42	\N	1784	11.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11823.webp	f	\N	f
1343	Kubota L3970	Kubota	L3970	2000	39	\N	1840	11.3	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11824.webp	t	\N	f
1344	Kubota L4470	Kubota	L4470	2000	44	\N	1935	13.3	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11825.webp	t	\N	f
1345	Kubota L5070	Kubota	L5070	2013	50	\N	1935	14.6	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11826.webp	t	\N	f
1346	Kubota L6070	Kubota	L6070	2013	60	\N	1989	19.4	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11827.webp	t	\N	f
151	John Deere 5700	John Deere	5700	1996	85	\N	3519	26.4	4x4	Diagonal 96 - 19	2438	4628	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11829.webp	t	\N	f
1347	CaseIH 4994	CaseIH	4994	1984	400	\N	12020	153.5	4x4	Diagonal 20.8-38	528	1863	\N	\N	76.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1183.webp	t	\N	f
3156	Zetor 16245	Zetor	16245	1990	135.9	\N	5216	49.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1735.webp	t	\N	f
1542	Kubota M105S	Kubota	M105S	2005	105	\N	3920	34.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1840.webp	t	\N	f
3214	Fiat 500	Fiat	500	1971	50	\N	2250	18.3	4x4	Diagonal 11-32	279	1288	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1977.webp	f	\N	f
3260	Fiat 82-94	Fiat	82 94	1993	80	\N	3800	29.4	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2025.webp	f	\N	f
1563	Kubota B7610	Kubota	B7610	2004	24	\N	620	6.6	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1861.webp	f	\N	f
157	John Deere 1R 25	John Deere	1R 25	2000	23.2	\N	815	6.5	4x4	Diagonal 12-16.5	305	937	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11853.webp	f	\N	f
3240	Fiat 44-28	Versatile	44 28	1979	280	\N	12552	102.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2005.webp	t	\N	f
3283	Fiat 513R	Fiat	513R	1960	55	\N	2530	20.2	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2049.webp	f	\N	f
164	John Deere 2027R	John Deere	2027R	2013	26.5	\N	879	7.5	4x4	Diagonal 14-17.5	356	1049	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td11860.webp	f	\N	f
3241	Fiat 44-33	Versatile	44 33	1979	330	\N	13302	121.1	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2006.webp	t	\N	f
3242	Fiat 44-35	Versatile	44 35	1979	350	\N	14152	128.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2007.webp	t	\N	f
3243	Fiat 55-90	Fiat	55 90	1984	55	\N	3140	20.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2008.webp	f	\N	f
3244	Fiat 60-90	Fiat	60 90	1984	60	\N	3480	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2009.webp	f	\N	f
3249	Fiat 90-90	Fiat	90 90	1984	90	\N	3870	33	4x4	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2014.webp	f	\N	f
1352	CaseIH 5220 Maxxum	CaseIH	5220 Maxxum	1992	80	\N	4699	29.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1187.webp	t	\N	f
1353	CaseIH 5230 Maxxum	CaseIH	5230 Maxxum	1992	90	\N	4819	33	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1188.webp	f	\N	f
1354	CaseIH 5240 Maxxum	CaseIH	5240 Maxxum	1992	100	\N	5019	36.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1189.webp	t	\N	f
165	John Deere 2350	John Deere	2350	1983	55	\N	3728	25.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td119.webp	f	\N	f
1355	CaseIH 5250 Maxxum	CaseIH	5250 Maxxum	1992	112	\N	5030	81.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1190.webp	t	\N	f
1356	CaseIH 7110	CaseIH	7110	1987	130	\N	6931	68.9	4x2	Radial 18.4R38	467	1760	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1191.webp	t	\N	f
1357	CaseIH 7120	CaseIH	7120	1987	150	\N	7221	86.9	4x2	Radial 18.4R38	467	1760	\N	\N	32.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1192.webp	t	\N	f
1358	CaseIH 7130	CaseIH	7130	1987	170	\N	7956	93.1	4x4	Radial 18.4R42	467	1861	\N	\N	36	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1193.webp	t	\N	f
3245	Fiat 65-90	Fiat	65 90	1987	65	\N	3089	23.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2010.webp	f	\N	f
3246	Fiat 70-90	Fiat	70 90	1984	70	\N	3329	25.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2011.webp	f	\N	f
3247	Fiat 80-90	Fiat	80 90	1984	80	\N	3420	29.4	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2012.webp	f	\N	f
3248	Fiat 85-90	Fiat	85 90	1989	85	\N	3480	31.2	4x4	Radial 480/70R34	480	1536	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2013.webp	t	\N	f
1361	CaseIH 7210	CaseIH	7210	1994	130	\N	7361	68.9	4x4	Diagonal 94 - 19	2388	4542	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1196.webp	t	\N	f
1359	CaseIH 7140	CaseIH	7140	1987	195	\N	7475	72.5	4x2	Radial 18.4R42	467	1861	\N	\N	42.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1194.webp	t	\N	f
1360	CaseIH 7150	CaseIH	7150	1990	215	\N	8431	84.9	4x4	Diagonal 20.8-38	528	1863	\N	\N	49.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1195.webp	t	\N	f
1362	CaseIH 7220	CaseIH	7220	1994	155	\N	7518	74.9	4x4	Diagonal 94 - 19	2388	4542	\N	\N	36.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1197.webp	t	\N	f
1363	CaseIH 7230	CaseIH	7230	1994	170	\N	7597	93.1	4x4	Diagonal 94 - 19	2388	4542	\N	\N	36	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1198.webp	t	\N	f
1364	CaseIH 7240	CaseIH	7240	1994	195	\N	7640	77.6	4x4	Diagonal 94 - 19	2388	4542	\N	\N	45	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1199.webp	t	\N	f
1365	CaseIH 7250	CaseIH	7250	1994	215	\N	7913	79.1	4x4	Diagonal 94 - 19	2388	4542	\N	\N	50	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1200.webp	t	\N	f
1366	CaseIH 8910	CaseIH	8910	1997	135	\N	7361	73.5	4x4	Diagonal 97 - 19	2464	4671	\N	\N	32.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1201.webp	t	\N	f
1367	CaseIH 8920	CaseIH	8920	1997	155	\N	7518	74.9	4x4	Diagonal 97 - 19	2464	4671	\N	\N	36.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1202.webp	t	\N	f
1368	CaseIH 8930	CaseIH	8930	1997	180	\N	7597	78	4x4	Diagonal 97 - 19	2464	4671	\N	\N	42.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1203.webp	t	\N	f
1369	CaseIH 8940	CaseIH	8940	1997	205	\N	7640	80.3	4x4	Diagonal 97 - 19	2464	4671	\N	\N	47.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1204.webp	t	\N	f
1370	CaseIH 8950	CaseIH	8950	1997	225	\N	7913	83.5	4x4	Diagonal 97 - 19	2464	4671	\N	\N	54.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1205.webp	t	\N	f
1376	CaseIH 9190	CaseIH	9190	2000	525	\N	18470	192.6	4x4	Diagonal 30.5-32	775	2130	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1211.webp	t	\N	f
1378	CaseIH 9230	CaseIH	9230	1990	235	\N	8164	111.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	45	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1213.webp	t	\N	f
1379	CaseIH 9240	CaseIH	9240	1990	235	\N	12797	127.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1214.webp	t	\N	f
1380	CaseIH 9250	CaseIH	9250	1990	300	\N	13635	144	4x4	Diagonal 20.8-38	528	1863	\N	\N	54.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1215.webp	t	\N	f
1381	CaseIH 9260	CaseIH	9260	1990	300	\N	9979	97.2	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1216.webp	t	\N	f
1382	CaseIH 9270	CaseIH	9270	1990	335	\N	15442	152.1	4x4	Diagonal 24.5-32	622	1871	\N	\N	65.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1217.webp	t	\N	f
3250	Fiat 100-90	Fiat	100 90	1984	100	\N	4280	36.7	4x2	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2015.webp	f	\N	f
166	John Deere 2550	John Deere	2550	1983	65	\N	3778	0.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	16.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td120.webp	f	\N	f
1371	CaseIH 9110	CaseIH	9110	1986	190	\N	7711	61.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1206.webp	t	\N	f
1372	CaseIH 9130	CaseIH	9130	1986	220	\N	8051	69.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1207.webp	t	\N	f
1373	CaseIH 9150	CaseIH	9150	1986	280	\N	10432	95	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1208.webp	t	\N	f
1374	CaseIH 9170	CaseIH	9170	1986	335	\N	13154	110.1	4x4	Diagonal 23.1-24	587	1607	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1209.webp	t	\N	f
167	John Deere 2750	John Deere	2750	1983	75	\N	3724	33.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	18.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td121.webp	t	\N	f
1375	CaseIH 9180	CaseIH	9180	1986	375	\N	13154	126.2	4x4	Diagonal 30.5-32	775	2130	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1210.webp	t	\N	f
1377	CaseIH 9210	CaseIH	9210	1990	200	\N	7711	61.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1212.webp	t	\N	f
1383	CaseIH 9280	CaseIH	9280	1990	375	\N	13154	126.2	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1218.webp	t	\N	f
1384	CaseIH 9310	CaseIH	9310	1996	205	\N	9537	61.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1219.webp	t	\N	f
1391	CaseIH 9390	CaseIH	9390	1997	425	\N	14742	140.5	4x4	Diagonal 97 - 19	2464	4671	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1226.webp	t	\N	f
1385	CaseIH 9330	CaseIH	9330	1996	240	\N	9537	114.8	4x4	Diagonal 18.4x3	467	871	\N	\N	50.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1220.webp	t	\N	f
1386	CaseIH 9350	CaseIH	9350	1996	310	\N	13426	131.6	4x4	Diagonal 96 - 19	2438	4628	\N	\N	56.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1221.webp	t	\N	f
1387	CaseIH 9370	CaseIH	9370	1996	360	\N	15325	163.8	4x4	Diagonal 96 - 19	2438	4628	\N	\N	67.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1222.webp	t	\N	f
1388	CaseIH Quadtrac 9370QT	CaseIH	Quadtrac 9370QT	1996	360	\N	19958	115.6	track	Diagonal 96 - 19	2438	4628	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1223.webp	t	\N	f
1389	CaseIH 9380	CaseIH	9380	1996	400	\N	14324	148.7	4x4	Diagonal 96 - 20	2438	4653	\N	\N	77.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1224.webp	t	\N	f
1390	CaseIH Quadtrac 9380QT	CaseIH	Quadtrac 9380QT	1998	400	\N	19958	130.6	track	Diagonal 98 - 19	2489	4714	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1225.webp	t	\N	f
1392	Kubota M110	Kubota	M110	1998	110	\N	4199	32.3	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1244.webp	t	\N	f
1393	Kubota M120	Kubota	M120	1998	120	\N	4399	55.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	23.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1245.webp	t	\N	f
168	John Deere 2950	John Deere	2950	1983	85	\N	4581	39	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td122.webp	f	\N	f
169	John Deere 790	Yanmar	deere 790	2000	30	\N	954	9.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1227.webp	f	\N	f
170	John Deere 4050	John Deere	4050	1983	130	\N	5034	49.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td123.webp	t	\N	f
171	John Deere 4250	John Deere	4250	1983	144	\N	5332	56.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	29.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td124.webp	t	\N	f
1394	Kubota B2410	Kubota	B2410	2000	24	\N	669	6.6	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1246.webp	f	\N	f
1395	Kubota B2710	Kubota	B2710	2000	27	\N	789	7.3	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1247.webp	f	\N	f
3251	Fiat 110-90	Fiat	110 90	1986	110	\N	4670	40.4	4x2	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2016.webp	f	\N	f
3252	Fiat 115-90	Fiat	115 90	1984	115	\N	5290	42.2	4x4	Diagonal 15-90	381	2934	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2017.webp	f	\N	f
3253	Fiat 130-90	Fiat	130 90	1984	130	\N	5790	47.7	4x4	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2018.webp	t	\N	f
3256	Fiat 180-90	Fiat	180 90	1984	180	\N	6890	66	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2021.webp	t	\N	f
3257	Fiat 60-94	Fiat	60 94	1993	60	\N	3150	22	4x4	Diagonal 12-36	305	1433	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2022.webp	f	\N	f
3258	Fiat 65-94	Fiat	65 94	1993	65	\N	3400	23.8	4x4	Diagonal 14-30	356	1367	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2023.webp	f	\N	f
3254	Fiat 140-90	Fiat	140 90	1984	140	\N	6471	51.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2019.webp	t	\N	f
3255	Fiat 160-90	Fiat	160 90	1984	160	\N	8465	58.7	4x4	Diagonal 23.1-34	587	1861	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2020.webp	t	\N	f
3259	Fiat 72-94	Fiat	72 94	1993	70	\N	3749	25.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2024.webp	f	\N	f
3261	Fiat 88-94	Fiat	88 94	1993	85	\N	3850	31.2	4x4	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2026.webp	t	\N	f
3262	Fiat F100	Fiat	F100	1990	100	\N	4600	36.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2027.webp	f	\N	f
1396	Kubota B2910	Kubota	B2910	2000	30	\N	799	8.1	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1248.webp	f	\N	f
1397	Kubota L3010	Kubota	L3010	1998	32.1	\N	1224	9.4	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1249.webp	f	\N	f
172	John Deere 4450	John Deere	4450	1983	158.2	\N	5781	66.8	4x4	Diagonal 18.4-38	467	1760	\N	\N	32.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td125.webp	t	\N	f
3263	Fiat F110	Fiat	F110	1990	110	\N	4800	40.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2028.webp	f	\N	f
3264	Fiat F115	Fiat	F115	1993	115	\N	4900	42.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2029.webp	f	\N	f
404	Massey Ferguson 1428	Iseki	ferguson 1428	2002	28.4	\N	913	9	4x4	Diagonal 80-18	2032	3912	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3869.webp	f	\N	f
1398	Kubota L3410	Kubota	L3410	1998	35.1	\N	1254	10.5	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1250.webp	f	\N	f
1400	Kubota L3710	Kubota	L3710	1998	38.5	\N	1340	11.6	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1252.webp	f	\N	f
1399	Kubota L4310	Kubota	L4310	1998	45.3	\N	1374	13.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1251.webp	f	\N	f
1401	Kubota M4030	Kubota	M4030	1986	48	\N	2180	25.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1253.webp	f	\N	f
1402	Kubota M5400	Kubota	M5400	1995	58	\N	1849	18.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1255.webp	f	\N	f
1403	Kubota M8200	Kubota	M8200	1997	85.3	\N	2732	26.8	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1256.webp	f	\N	f
1404	Kubota M9000	Kubota	M9000	1997	92.1	\N	2794	40	4x4	Diagonal 12.4-24	315	1145	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1257.webp	f	\N	f
1405	Kubota B1550	Kubota	B1550	1988	17	\N	610	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1259.webp	f	\N	f
173	John Deere 4650	John Deere	4650	1983	187.7	\N	7568	74.5	4x4	Diagonal 20.8-38	528	1863	\N	\N	37.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td126.webp	t	\N	f
1406	Kubota B1700	Kubota	B1700	1995	17	\N	680	5.1	4x4	Diagonal 8.3-16	211	765	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1260.webp	f	\N	f
1407	Kubota B1750	Kubota	B1750	1988	20	\N	627	6.1	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1261.webp	f	\N	f
1408	Kubota B2100	Kubota	B2100	1995	21	\N	680	6.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1262.webp	f	\N	f
1409	Kubota B2150	Kubota	B2150	1988	24	\N	829	7.3	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1263.webp	f	\N	f
1410	Kubota B2400	Kubota	B2400	1995	24	\N	712	6.6	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1264.webp	f	\N	f
1412	Kubota B5100	Kubota	B5100	1978	12	\N	405	3.7	4x4	Diagonal 27x8.50-15	216	686	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1266.webp	f	\N	f
1413	Kubota B5200	Kubota	B5200	1983	13	\N	535	4.2	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1267.webp	f	\N	f
1414	Kubota B6000	Kubota	B6000	1973	10.9	\N	476	4	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1268.webp	f	\N	f
1415	Kubota B6100	Kubota	B6100	1978	14	\N	469	4.4	4x4	Diagonal 7.2-16	183	717	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1269.webp	f	\N	f
174	John Deere 4850	John Deere	4850	1983	207.9	\N	7918	83.6	4x4	Diagonal 20.8-38	528	1863	\N	\N	41.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td127.webp	t	\N	f
3265	Fiat F120	Fiat	F120	1990	120	\N	5100	44	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2030.webp	f	\N	f
3266	Fiat F130	Fiat	F130	1990	130	\N	5000	47.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2031.webp	t	\N	f
3267	Fiat F140	Fiat	F140	1993	140	\N	5300	51.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2032.webp	t	\N	f
3280	Fiat 431R	Fiat	431R	1964	40	\N	1519	14.7	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2046.webp	f	\N	f
3284	Fiat 80R	Fiat	80R	1961	84	\N	3600	30.8	4x2	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2050.webp	f	\N	f
3269	Fiat 702	Fiat	702	1919	30	\N	2700	11	4x2	Diagonal 12-51	305	1814	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2034.webp	f	\N	f
3270	Fiat 703	Fiat	703	1919	35	\N	2700	12.8	4x2	Diagonal 12-51	305	1814	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2036.webp	f	\N	f
3271	Fiat 18	Fiat	18	1956	18	\N	830	6.6	4x2	Diagonal 8-24	203	955	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2037.webp	f	\N	f
3272	Fiat 211R	Fiat	211R	1959	21.13	\N	899	7.8	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2038.webp	f	\N	f
3273	Fiat 211Rb	Fiat	211Rb	1959	21	\N	870	7.7	4x2	Diagonal 8.00-24	203	955	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2039.webp	f	\N	f
3276	Fiat 251R	Fiat	251R	1959	21.13	\N	1152	7.8	4x2	Diagonal 7.50-20	191	832	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2042.webp	f	\N	f
3277	Fiat 411R	Fiat	411R	1958	40	\N	1617	20.1	4x2	Diagonal 11-28	279	1186	\N	\N	11	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2043.webp	f	\N	f
3281	Fiat 441R	Fiat	441R	1961	40	\N	1769	14.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2047.webp	f	\N	f
3282	Fiat 512R	Fiat	512R	1959	59	\N	2370	21.6	4x2	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2048.webp	f	\N	f
3286	Deutz D 2505	Deutz	D 2505	1965	22	\N	1549	8.1	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2175.webp	f	\N	f
3287	Deutz D 3005	Deutz	D 3005	1965	28	\N	1635	10.3	4x2	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2176.webp	f	\N	f
3288	Deutz D 4005	Deutz	D 4005	1965	35	\N	1779	12.8	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2177.webp	f	\N	f
3290	Deutz D 5005	Deutz	D 5005	1965	45	\N	2100	16.5	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2179.webp	f	\N	f
3291	Deutz D 5505	Deutz	D 5505	1965	51.3	\N	2459	18.8	4x2	Diagonal 11-36	279	1389	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2180.webp	f	\N	f
3292	Deutz D 6005	Deutz	D 6005	1966	58	\N	2565	21.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2181.webp	f	\N	f
3293	Deutz D 8005	Deutz	D 8005	1965	80	\N	4300	29.4	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2182.webp	f	\N	f
3295	Deutz D 2506	Deutz	D 2506	1968	24	\N	1730	8.8	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2184.webp	f	\N	f
3294	Deutz D 9005	Deutz	D 9005	1966	85	\N	4300	31.2	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2183.webp	f	\N	f
3302	Deutz D 7006	Deutz	D 7006	1969	71	\N	3190	26	4x4	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2191.webp	f	\N	f
3303	Deutz D 7506	Deutz	D 7506	1968	75	\N	3375	27.5	4x4	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2192.webp	f	\N	f
3296	Deutz D 3006	Deutz	D 3006	1967	30	\N	1868	11	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2185.webp	f	\N	f
3297	Deutz D 4006	Deutz	D 4006	1968	35	\N	2270	12.8	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2186.webp	f	\N	f
3298	Deutz D 4506	Deutz	D 4506	1971	40	\N	2372	14.7	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2187.webp	f	\N	f
3299	Deutz D 5006	Deutz	D 5006	1968	48	\N	2050	17.6	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2188.webp	f	\N	f
3300	Deutz D 5506	Deutz	D 5506	1967	52	\N	2494	19.1	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2189.webp	f	\N	f
1566	Ford Golden Jubilee NAA	Ford	Golden Jubilee NAA	1953	30.15	\N	1156	14.4	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td219.webp	f	\N	f
3301	Deutz D 6006	Deutz	D 6006	1968	62	\N	3132	22.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2190.webp	f	\N	f
3304	Deutz D 8006	Deutz	D 8006	1967	80	\N	3214	39.6	4x4	Diagonal 16.9-34	429	1593	\N	\N	19.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2193.webp	f	\N	f
3305	Deutz D 5206	Deutz	D 5206	1974	51	\N	2435	18.7	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2194.webp	f	\N	f
3306	Deutz D 6206	Deutz	D 6206	1974	60	\N	2698	22	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2195.webp	f	\N	f
3307	Deutz D 6806	Deutz	D 6806	1974	67	\N	3274	24.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2196.webp	f	\N	f
3308	Deutz D 7206	Deutz	D 7206	1974	70	\N	3329	25.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2197.webp	f	\N	f
1422	Kubota L175	Kubota	L175	1973	17	\N	648	6.2	4x2	Diagonal 8-24	203	955	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1276.webp	f	\N	f
1423	Kubota L185	Kubota	L185	1977	17	\N	723	5.5	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1277.webp	f	\N	f
1424	Kubota L200	Kubota	L200	1972	21	\N	907	5.4	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1278.webp	f	\N	f
1425	Kubota L210	Kubota	L210	1972	21	\N	979	9	4x2	Diagonal 9-24	229	998	\N	\N	5.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1279.webp	f	\N	f
1416	Kubota B6200	Kubota	B6200	1983	15	\N	554	4.6	4x4	Diagonal 29x12.00-15	305	737	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1270.webp	f	\N	f
1417	Kubota B7100	Kubota	B7100	1976	16	\N	489	4.8	4x4	Diagonal 8.3-16	211	765	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1271.webp	f	\N	f
1418	Kubota B7200	Kubota	B7200	1983	17	\N	504	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1272.webp	f	\N	f
1419	Kubota B7300	Kubota	B7300	1997	16	\N	595	4.6	4x4	Diagonal 31x15.5-15	394	787	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1273.webp	f	\N	f
1420	Kubota B8200	Kubota	B8200	1983	19	\N	709	5.9	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1274.webp	f	\N	f
1421	Kubota B9200	Kubota	B9200	1986	22.5	\N	712	5.9	4x2	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1275.webp	f	\N	f
175	John Deere 655	John Deere	655	1986	16	\N	741	3.9	4x4	Diagonal 7.2-16	183	717	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td128.webp	f	\N	f
1426	Kubota L225	Kubota	L225	1974	24	\N	904	9	4x2	Diagonal 9.5-24	241	1020	\N	\N	6.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1280.webp	f	\N	f
1427	Kubota L235	Kubota	L235	1981	23.5	\N	884	13.6	4x4	Diagonal 9.5-24	241	1020	\N	\N	5.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1281.webp	f	\N	f
1428	Kubota L245	Kubota	L245	1976	25	\N	907	9.2	4x4	Diagonal 13.6-16	345	994	\N	\N	6.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1282.webp	f	\N	f
3309	Deutz D 9006	Deutz	D 9006	1967	92	\N	4500	33.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2198.webp	f	\N	f
3310	Deutz D 10006	Deutz	D 10006	1969	100	\N	4198	36.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2199.webp	f	\N	f
1429	Kubota L260	Kubota	L260	1970	26	\N	1197	11.5	4x2	Diagonal 10-24	254	1041	\N	\N	6.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1283.webp	f	\N	f
1437	Kubota L2250	Kubota	L2250	1985	26.5	\N	984	11.9	4x4	Diagonal 9.5-24	241	1020	\N	\N	4.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1291.webp	f	\N	f
1440	Kubota L2550	Kubota	L2550	1985	29.5	\N	1120	14.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	5.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1294.webp	f	\N	f
1442	Kubota L2850	Kubota	L2850	1985	34	\N	1229	17.9	4x4	Diagonal 12.4-24	315	1145	\N	\N	6.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1296.webp	f	\N	f
1430	Kubota L275	Kubota	L275	1981	27.5	\N	1179	14.7	4x4	Diagonal 13.6-16	345	994	\N	\N	6.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1284.webp	f	\N	f
1431	Kubota L285	Kubota	L285	1975	30	\N	1011	9.7	4x2	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1285.webp	f	\N	f
1432	Kubota L295	Kubota	L295	1978	30	\N	1179	15.5	4x4	Diagonal 12.4-24	315	1145	\N	\N	7.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1286.webp	f	\N	f
1433	Kubota L305	Kubota	L305	1979	30	\N	1295	19.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	7.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1287.webp	f	\N	f
1434	Kubota L345	Kubota	L345	1978	34	\N	1422	20.1	4x4	Diagonal 13.6-28	345	1298	\N	\N	8.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1288.webp	f	\N	f
1435	Kubota L355	Kubota	L355	1982	36	\N	1369	10.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1289.webp	f	\N	f
176	John Deere 755	John Deere	755	1986	20	\N	807	5.5	4x4	Diagonal 9.5x16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td129.webp	f	\N	f
1436	Kubota L2050	Kubota	L2050	1989	25	\N	949	7.3	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1290.webp	f	\N	f
1438	Kubota L2350	Kubota	L2350	1991	25	\N	1000	7.5	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1292.webp	f	\N	f
1439	Kubota L2500	Kubota	L2500	1998	27	\N	1001	8.3	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1293.webp	f	\N	f
1441	Kubota L2650	Kubota	L2650	1991	29	\N	1179	8.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1295.webp	f	\N	f
1443	Kubota L2900	Kubota	L2900	1994	32.1	\N	1229	9.2	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1297.webp	f	\N	f
1444	Kubota L2950	Kubota	L2950	1991	31.7	\N	1211	9.5	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1298.webp	f	\N	f
3312	Deutz D 13006	Deutz	D 13006	1972	130	\N	4762	47.7	4x4	Diagonal 20.5-38	521	1850	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2201.webp	t	\N	f
3313	Deutz D 16006	Deutz	D 16006	1970	160	\N	9001	58.7	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td2202.webp	f	\N	f
1567	Ford 2N	Ford	2N	1942	23.87	\N	1392	8.8	4x2	Diagonal 10.00x28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td221.webp	f	\N	f
1453	Kubota L4200	Kubota	L4200	1994	45.3	\N	1374	13.6	4x4	Diagonal 94 - 19	2388	4542	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1307.webp	f	\N	f
1445	Kubota L3250	Kubota	L3250	1989	40	\N	1247	11.7	4x4	Diagonal 21.5-16.1	546	1337	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1299.webp	f	\N	f
177	John Deere 855	John Deere	855	1986	24	\N	848	7	4x4	Diagonal 9.5x16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td130.webp	f	\N	f
1446	Kubota L3300	Kubota	L3300	1994	35.1	\N	1254	10.3	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1300.webp	f	\N	f
1447	Kubota L3350	Kubota	L3350	1985	40	\N	1710	19.7	4x4	Diagonal 12.4-24	315	1145	\N	\N	7.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1301.webp	f	\N	f
1448	Kubota L3450	Kubota	L3450	1990	36.7	\N	1290	11	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1302.webp	f	\N	f
1449	Kubota L3600	Kubota	L3600	1994	38.5	\N	1340	11.4	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1303.webp	f	\N	f
1450	Kubota L3650	Kubota	L3650	1990	40.5	\N	1319	12.1	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1304.webp	f	\N	f
1451	Kubota L3750	Kubota	L3750	1984	45	\N	1775	21.6	4x4	Diagonal 12.4-28	315	1247	\N	\N	8.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1305.webp	f	\N	f
1452	Kubota L4150	Kubota	L4150	1984	50	\N	1850	23	4x4	Diagonal 16.9-24	429	1339	\N	\N	9.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1306.webp	f	\N	f
1454	Kubota L4350	Kubota	L4350	1991	47.5	\N	1750	13.9	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1308.webp	f	\N	f
1455	Kubota L4850	Kubota	L4850	1991	53	\N	1850	15.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1309.webp	f	\N	f
178	John Deere 3150	John Deere	3150	1985	95	\N	5338	46.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td131.webp	f	\N	f
1456	Kubota L5450	Kubota	L5450	1991	59.5	\N	2000	18	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1310.webp	f	\N	f
1568	Ford 8N	Ford	8N	1947	27.32	\N	1093	12.5	4x2	Diagonal 10-28	254	1143	\N	\N	9.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td223.webp	f	\N	f
1575	Kubota L1501	Kubota	L1501	1975	14.8	\N	749	5.4	4x4	Diagonal 8-22	203	904	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2293.webp	f	\N	f
1569	Ford 9N	Ford	9N	1939	23.87	\N	970	9.9	4x2	Diagonal 8.00-32	203	1158	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td225.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1607/	f
1570	Ford TW-10	Ford	TW 10	1979	127.9	\N	5103	53.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td226.webp	f	\N	f
312	John Deere Unstyled D	John Deere	Unstyled D	1923	27	\N	1855	14.6	4x2	Diagonal 46x12	1168	2291	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td23.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1041/	f
1577	Ford FW-40	Steiger	fw 40	1977	295	\N	13893	125.6	4x4	Diagonal 24.5x32	622	1871	\N	\N	62.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td231.webp	f	\N	f
1457	Kubota M4000	Kubota	M4000	1977	47.5	\N	1871	15	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1311.webp	f	\N	f
179	John Deere 2850	John Deere	2850	1986	86	\N	3925	31.6	4x4	Radial 14.9R38	378	1609	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1312.webp	t	\N	f
1458	Kubota M4050	Kubota	M4050	1982	48	\N	2086	27	4x4	Diagonal 13.6-28	345	1298	\N	\N	12.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1313.webp	f	\N	f
1459	Kubota M4500	Kubota	M4500	1978	55.5	\N	2154	26.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	13.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1314.webp	f	\N	f
1460	Kubota M4700	Kubota	M4700	1995	51	\N	1799	15.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1315.webp	f	\N	f
1461	Kubota M4950	Kubota	M4950	1983	51	\N	2473	30	4x4	Diagonal 14.9-28	378	1355	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1316.webp	f	\N	f
1462	Kubota M5030	Kubota	M5030	1986	54	\N	2259	26.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1317.webp	f	\N	f
1578	Ford FW-60	Steiger	fw 60	1977	335	\N	14106	130.3	4x4	Diagonal 24.5x32	622	1871	\N	\N	68.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td232.webp	t	\N	f
1579	Ford 640	Ford	640	1954	30	\N	1374	13.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td233.webp	f	\N	f
1580	Ford 641	Ford	641	1957	48.4	\N	1492	18.2	4x2	Diagonal 11-28	279	1186	\N	\N	8.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td234.webp	f	\N	f
1463	Kubota M5500	Kubota	M5500	1979	63	\N	2299	34.5	4x4	Diagonal 16.9-28	429	1441	\N	\N	13.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1318.webp	f	\N	f
1581	New Holland 8670A	New Holland	8670A	2001	145	\N	8477	53.2	4x4	Diagonal 01 - 20	25	551	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2363.webp	t	\N	f
1582	New Holland 8770A	New Holland	8770A	2001	160	\N	8477	58.7	4x4	Diagonal 01 - 20	25	551	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2364.webp	t	\N	f
1583	New Holland 8870A	New Holland	8870A	2001	180	\N	8477	66	4x4	Diagonal 01 - 20	25	551	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2365.webp	t	\N	f
1584	New Holland 8970A	New Holland	8970A	2001	210	\N	8477	77	4x4	Diagonal 01 - 20	25	551	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2366.webp	t	\N	f
1464	Kubota M5950	Kubota	M5950	1983	61	\N	2573	37.1	4x4	Diagonal 16.9-28	429	1441	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1319.webp	f	\N	f
180	John Deere 900HC	Yanmar	deere 900hc	1986	25	\N	1299	8.1	4x2	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td132.webp	f	\N	f
1465	Kubota M6030	Kubota	M6030	1986	61	\N	2390	31.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1320.webp	f	\N	f
1466	Kubota M6800	Kubota	M6800	1997	70.9	\N	2351	32.2	4x4	Diagonal 9.5-24	241	1020	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1321.webp	f	\N	f
1467	Kubota M6950	Kubota	M6950	1983	71	\N	3003	37.6	4x4	Diagonal 18.4-28	467	1506	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1322.webp	f	\N	f
1585	Ford 740	Ford	740	1954	30	\N	1396	13.9	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td238.webp	f	\N	f
3423	J.I. Case 511-B	Case IH	511 B	1958	45	\N	2141	25.1	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td478.webp	f	\N	f
1586	Ford 841 Powermaster	Ford	841 Powermaster	1957	62.6	\N	1341	20.6	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td239.webp	f	\N	f
1468	Kubota M7030	Kubota	M7030	1986	71	\N	2739	33	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1323.webp	f	\N	f
1469	Kubota M7500	Kubota	M7500	1979	81	\N	2544	34.8	4x4	Diagonal 18.4-28	467	1506	\N	\N	16.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1324.webp	f	\N	f
1470	Kubota M7580	Kubota	M7580	1991	77	\N	3099	25.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1325.webp	f	\N	f
313	John Deere GP	John Deere	GP	1928	20	\N	1632	11.1	4x2	Diagonal 42.75x10	1086	2100	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td24.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1043/	f
1587	Ford 850	Ford	850	1954	40	\N	1292	23	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td240.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1027/	f
1588	Ford 860	Ford	860	1954	40	\N	1292	20.1	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td242.webp	f	\N	f
1589	Ford 960	Ford	960	1954	40	\N	1487	20.8	4x2	Diagonal 12x28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td244.webp	f	\N	f
1471	Kubota M7950	Kubota	M7950	1983	81	\N	3091	42.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1326.webp	f	\N	f
1472	Kubota M8030	Kubota	M8030	1986	81	\N	2799	36	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1327.webp	f	\N	f
1473	Kubota M8580	Kubota	M8580	1991	85	\N	3799	29.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1328.webp	f	\N	f
1474	Kubota M8950	Kubota	M8950	1984	96	\N	3504	46.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1329.webp	t	\N	f
181	John Deere 2155	John Deere	2155	1987	55	\N	2715	17.7	4x4	Diagonal 16.9-28	429	1441	\N	\N	11.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td133.webp	f	\N	f
1590	Ford 1100	Shibaura	1100	1979	13	\N	609	4	4x4	Diagonal 8.00-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td245.webp	f	\N	f
1591	Ford 1110	Shibaura	1110	1983	13	\N	633	4.2	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td246.webp	f	\N	f
1592	Ford 1200	Shibaura	1200	1979	16	\N	609	5	4x4	Diagonal 8.00-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td247.webp	f	\N	f
1593	Ford 1210	Shibaura	1210	1983	16	\N	654	5	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td248.webp	f	\N	f
1594	Ford 1300	Shibaura	1300	1979	16	\N	970	5	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td249.webp	f	\N	f
314	John Deere A	John Deere	A	1934	24	\N	1715	13	4x2	Diagonal 50x6	1270	2311	\N	\N	8.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td25.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1045/	f
1595	Ford 1500	Shibaura	1500	1979	19.9	\N	1045	6.2	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td250.webp	f	\N	f
1596	Ford 1600	Shibaura	1600	1976	23	\N	1128	11.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	6.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td251.webp	f	\N	f
1597	Ford 1700	Shibaura	1700	1979	25	\N	1194	12.5	4x4	Diagonal 13.6-16	345	994	\N	\N	6.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td252.webp	f	\N	f
1598	Ford 1710	Shibaura	1710	1983	26	\N	1220	12	4x4	Diagonal 11.2-24	284	1093	\N	\N	7.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td253.webp	f	\N	f
1599	Ford 1900	Shibaura	1900	1979	30	\N	1325	13.2	4x4	Diagonal 13.6-16	345	994	\N	\N	8.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td254.webp	f	\N	f
1600	Ford 2000	Ford	2000	1962	48.4	\N	1369	11.4	4x2	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td255.webp	f	\N	f
1601	Ford 2310	Ford	2310	1982	36.5	\N	1559	19.8	4x4	Diagonal 13.6-28	345	1298	\N	\N	8.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td256.webp	f	\N	f
1602	Ford 2600	Ford	2600	1975	36.5	\N	1640	19.8	4x2	Diagonal 12.4-28	315	1247	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td257.webp	f	\N	f
1603	Ford 2610	Ford	2610	1982	42.5	\N	1576	19.8	4x2	Diagonal 12.4-28	315	1247	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td258.webp	f	\N	f
1604	Ford 3000	Ford	3000	1965	46.7	\N	1678	22.7	4x2	Diagonal 12.4-28	315	1247	\N	\N	9.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td259.webp	f	\N	f
1605	Ford 3600	Ford	3600	1975	48	\N	1744	22.7	4x2	Diagonal 12.4-28	315	1247	\N	\N	10.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td260.webp	f	\N	f
1606	Ford 3610	Ford	3610	1982	49.7	\N	1662	22.8	4x2	Diagonal 13.6-28	345	1298	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td261.webp	f	\N	f
1607	Ford 4000	Ford	4000	1962	62.5	\N	1434	16	4x2	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td262.webp	f	\N	f
1608	Ford 4100	Ford	4100	1975	52	\N	2111	24.7	4x2	Diagonal 14.9-28	378	1355	\N	\N	11.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td263.webp	f	\N	f
1610	Ford 5000	Ford	5000	1965	69	\N	2603	31.1	4x2	Diagonal 12.4-38	315	1501	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td266.webp	f	\N	f
182	John Deere 2355	John Deere	2355	1987	64	\N	3010	20.5	4x4	Diagonal 16.9-28	429	1441	\N	\N	12.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td134.webp	f	\N	f
183	John Deere 4100	John Deere	4100	1998	20	\N	688	7.3	4x4	Diagonal 8.00-16	203	752	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td135.webp	f	\N	f
184	John Deere 2555	John Deere	2555	1987	77	\N	2820	23.8	4x4	Diagonal 12.4-42	315	1602	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td136.webp	t	\N	f
185	John Deere 2755	John Deere	2755	1987	88	\N	2840	27.5	4x4	Diagonal 16.9-24	429	1339	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td137.webp	t	\N	f
186	John Deere WA-14	Wagner	deere wa 14	1968	225	\N	12029	82.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1373.webp	f	\N	f
187	John Deere WA-17	Wagner	deere wa 17	1968	280	\N	12827	102.7	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1374.webp	t	\N	f
1612	Ford 5900	Ford	5900	1985	73	\N	2612	22.7	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td268.webp	f	\N	f
1613	Ford 6000	Ford	6000	1961	66.9	\N	2948	32.2	4x2	Diagonal 13.6x38	345	1552	\N	\N	19.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td269.webp	f	\N	f
1615	Ford 6700	Ford	6700	1977	75.5	\N	3129	31.7	4x4	Diagonal 16.9-38	429	1695	\N	\N	17.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td271.webp	f	\N	f
188	John Deere Dain AWD	John Deere	Dain AWD	1918	24	\N	2086	8.8	4x2	Diagonal 40x20	1016	2235	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1375.webp	f	\N	f
189	John Deere 9620	John Deere	9620	2004	500	\N	16370	227.7	4x4	Radial 480/80R46	480	1936	\N	\N	82.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1376.webp	t	\N	f
317	John Deere 8130	John Deere	8130	2006	225	\N	9876	84.2	4x2	Diagonal 06 - 20	152	767	\N	\N	42.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2728.webp	t	\N	f
318	John Deere 8230	John Deere	8230	2006	245	\N	10771	974.1	4x4	Diagonal 06 - 20	152	767	\N	\N	46.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2729.webp	t	\N	f
190	John Deere 9520	John Deere	9520	2002	450	\N	16370	205.3	4x4	Radial 480/80R46	480	1936	\N	\N	75.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1377.webp	t	\N	f
316	John Deere G Unstyled	John Deere	G Unstyled	1937	31.44	\N	2268	18.2	4x2	Diagonal 51.5x7	1308	2402	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td27.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1048/	f
1616	Ford 6710	Ford	6710	1982	82	\N	2877	35.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td272.webp	f	\N	f
1617	New Holland 9280	Versatile	holland 9280	1994	250	\N	10518	80.7	4x4	Diagonal 20.8x38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2727.webp	t	\N	f
191	John Deere 9420	John Deere	9420	2002	425	\N	15817	170.9	4x4	Diagonal 02 - 20	51	594	\N	\N	65.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1378.webp	t	\N	f
192	John Deere 9320	John Deere	9320	2002	375	\N	15572	170.8	4x4	Diagonal 02 - 20	51	594	\N	\N	79.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1379.webp	t	\N	f
194	John Deere 9220	John Deere	9220	2002	325	\N	14938	159.4	4x4	Diagonal 02 - 20	51	594	\N	\N	69.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1380.webp	t	\N	f
195	John Deere 9120	John Deere	9120	2002	280	\N	14047	156.6	4x4	Diagonal 02 - 20	51	594	\N	\N	55.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1381.webp	t	\N	f
196	John Deere 9620T	John Deere	9620T	2004	500	\N	17690	217.9	track	Diagonal 04 - 20	102	681	\N	\N	75.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1382.webp	t	\N	f
197	John Deere 9520T	John Deere	9520T	2002	450	\N	17690	226	track	Diagonal 02 - 20	51	594	\N	\N	77.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1383.webp	t	\N	f
198	John Deere 9420T	John Deere	9420T	2002	425	\N	17690	188.7	track	Diagonal 02 - 20	51	594	\N	\N	71.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1384.webp	t	\N	f
199	John Deere 9320T	John Deere	9320T	2002	375	\N	17690	184.5	track	Diagonal 02 - 20	51	594	\N	\N	83.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1385.webp	t	\N	f
319	John Deere 8330	John Deere	8330	2006	275	\N	10771	82.2	track	Diagonal 06 - 20	152	767	\N	\N	53	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2730.webp	t	\N	f
321	John Deere 8530	John Deere	8530	2006	330	\N	12156	109.6	4x2	Diagonal 06 - 20	152	767	\N	\N	63.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2732.webp	t	\N	f
322	John Deere 8230T	John Deere	8230T	2006	265	\N	12439	119.7	track	Diagonal 06 - 20	152	767	\N	\N	47.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2733.webp	f	\N	f
323	John Deere 8330T	John Deere	8330T	2006	310	\N	12859	133	track	Diagonal 06 - 20	152	767	\N	\N	57.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2734.webp	f	\N	f
193	John Deere 2855N	John Deere	2855N	1987	80	\N	2553	29.4	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td138.webp	t	\N	f
200	John Deere 2955	John Deere	2955	1987	97	\N	3713	44.3	4x4	Diagonal 15.5-38	394	1634	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td139.webp	f	\N	f
201	John Deere 4055	John Deere	4055	1988	126.1	\N	5502	62	4x4	Diagonal 18.4-38	467	1760	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td140.webp	t	\N	f
1618	Ford 7000	Ford	7000	1971	93	\N	2857	36.2	4x2	Diagonal 13.6-38	345	1552	\N	\N	19.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td273.webp	t	\N	f
3024	Belarus MTZ-50	Belarus	MTZ 50	1962	55	\N	2790	20.2	4x2	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1406.webp	f	\N	f
3025	Belarus MTZ-52	Belarus	MTZ 52	1962	55	\N	2989	20.2	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1407.webp	f	\N	f
324	John Deere 8430T	John Deere	8430T	2006	335	\N	13059	143.2	track	Diagonal 06 - 20	152	767	\N	\N	59.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2735.webp	f	\N	f
202	John Deere 1030	John Deere	1030	1973	48.3	\N	2700	14.3	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1400.webp	f	\N	f
203	John Deere 1630	John Deere	1630	1973	59	\N	2168	18.3	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1401.webp	f	\N	f
204	John Deere 1830	John Deere	1830	1973	68	\N	2540	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1402.webp	f	\N	f
205	John Deere 3130	John Deere	3130	1973	96.5	\N	3719	27.6	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1403.webp	t	\N	f
3026	Belarus MTZ-80	Belarus	MTZ 80	1975	80	\N	3556	36.2	4x2	Diagonal 15.5-38	394	1634	\N	\N	18.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1408.webp	f	\N	f
3027	Belarus MTZ-102	Belarus	MTZ 102	2000	100	\N	4091	36.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1409.webp	t	\N	f
206	John Deere 4255	John Deere	4255	1988	142.2	\N	5545	70.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	27.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td141.webp	t	\N	f
1620	Ford 7400	Ford	7400	2000	100	\N	3150	36.7	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td276.webp	f	\N	f
3031	Belarus 220	Belarus	220	1995	22	\N	1230	7	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1415.webp	f	\N	f
1619	Ford 7200	Ford	7200	1973	89	\N	2835	30.5	4x2	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td275.webp	t	\N	f
1621	Ford 7600	Ford	7600	1975	96.7	\N	2531	34.6	4x4	Diagonal 15.5-38	394	1634	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td277.webp	t	\N	f
1622	Ford 7700	Ford	7700	1975	96.7	\N	3810	34.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td278.webp	t	\N	f
1623	Ford 8000	Ford	8000	1968	115.5	\N	4526	51.2	4x2	Diagonal 18.4-34	467	1658	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td279.webp	f	\N	f
325	John Deere L	John Deere	L	1937	9.27	\N	687	5.5	4x2	Diagonal 6.00-22	152	818	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td28.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1053/	f
1624	Ford 8600	Ford	8600	1972	110.69	\N	4091	50.5	4x2	Diagonal 18.4-34	467	1658	\N	\N	27.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td280.webp	f	\N	f
1625	Ford 8700	Ford	8700	1977	127	\N	4445	51.5	4x4	Diagonal 15-38	381	1613	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td281.webp	f	\N	f
1626	Ford 9000	Ford	9000	1970	145	\N	4445	62.2	4x2	Diagonal 23.1-34	587	1861	\N	\N	30.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td282.webp	t	\N	f
1627	Ford 9600	Ford	9600	1972	135.46	\N	5379	54.3	4x2	Diagonal 23.1-34	587	1861	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td283.webp	t	\N	f
1628	Ford 9700	Ford	9700	1977	146	\N	4944	66.8	4x4	Diagonal 15-38	381	1613	\N	\N	34.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td284.webp	t	\N	f
326	John Deere LA	John Deere	LA	1941	12.93	\N	997	8.6	4x2	Diagonal 8.00-24	203	955	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td29.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1057/	f
207	John Deere 4955	John Deere	4955	1988	225.3	\N	8332	105.5	4x4	Diagonal 88 - 19	2235	4282	\N	\N	41.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td142.webp	t	\N	f
3032	Belarus 250AS	Belarus	250AS	1979	31	\N	1950	11.4	4x2	Diagonal 10-28	254	1143	\N	\N	7.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1416.webp	f	\N	f
3034	Belarus 300	Belarus	300	1995	36	\N	2041	10.6	4x2	Diagonal 10.00-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1420.webp	f	\N	f
3035	Belarus 305	Belarus	305	2000	36	\N	2063	10.6	4x2	Diagonal 10.00-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1421.webp	f	\N	f
3036	Belarus 310	Belarus	310	1989	36	\N	2177	10.6	4x4	Diagonal 10.00-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1422.webp	f	\N	f
3037	Belarus 400A	Belarus	400A	1978	57	\N	2993	33.1	4x2	Diagonal 13.6-38	345	1552	\N	\N	11.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1423.webp	f	\N	f
208	John Deere 4555	John Deere	4555	1988	173	\N	8053	93.1	4x4	Diagonal 88 - 19	2235	4282	\N	\N	32.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td143.webp	t	\N	f
3042	Belarus 505	Belarus	505	1983	65	\N	3619	21.6	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1429.webp	f	\N	f
329	Massey Ferguson 148	Massey Ferguson	148	1972	49	\N	1784	14.1	4x2	Diagonal 11x32	279	1288	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2990.webp	f	\N	f
3043	Belarus 510	Belarus	510	1998	62	\N	3175	22.7	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1430.webp	f	\N	f
328	John Deere 4500	John Deere	4500	1998	39	\N	1564	12.1	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td2966.webp	f	\N	f
1629	Ford TW-25	Ford	TW 25	1983	160	\N	5564	69.5	4x4	Diagonal 20.8x38	528	1863	\N	\N	34.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2967.webp	t	\N	f
330	John Deere H	John Deere	H	1939	14	\N	943	8.2	4x2	Diagonal 7.50-32	191	1137	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td30.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1052/	f
3044	Belarus 520	Belarus	520	1979	65	\N	2948	21.3	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1431.webp	f	\N	f
3045	Belarus 525	Belarus	525	1983	65	\N	2948	23.1	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1432.webp	f	\N	f
3046	Belarus 530	Belarus	530	1994	55	\N	2721	19.1	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1433.webp	f	\N	f
3047	Belarus 532	Belarus	532	1994	55	\N	2948	19.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1434.webp	f	\N	f
3049	Belarus 562	Belarus	562	1981	70	\N	3240	21.3	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1436.webp	f	\N	f
3050	Belarus 570	Belarus	570	1992	61.24	\N	3855	41.5	4x2	Diagonal 15.5-38	394	1634	\N	\N	13.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1437.webp	f	\N	f
3051	Belarus 572	Belarus	572	1992	65	\N	4148	41.5	4x4	Diagonal 15.5-38	394	1634	\N	\N	13.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1438.webp	f	\N	f
1633	New Holland Boomer TZ25DA	New Holland	holland tz25da	2005	25	\N	598	7	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3090.webp	f	\N	f
1636	New Holland TC23DA	New Holland	holland tc23da	2005	23	\N	722	6.4	4x4	Diagonal 31x13.5-15	343	787	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3093.webp	f	\N	f
1638	New Holland TC26DA	New Holland	holland tc26da	2005	26	\N	725	7.5	4x4	Diagonal 31x13.5-15	343	787	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3095.webp	f	\N	f
3052	Belarus 611	Belarus	611	1980	67	\N	3489	22.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1439.webp	f	\N	f
209	John Deere 4455	John Deere	4455	1988	156.9	\N	6416	77.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	30.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td144.webp	t	\N	f
3053	Belarus 615	Belarus	615	1992	67	\N	3900	22.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1440.webp	f	\N	f
3054	Belarus 650	Belarus	650	1991	67	\N	3991	22.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1441.webp	f	\N	f
3055	Belarus 652	Belarus	652	1991	67	\N	3991	22.4	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1442.webp	f	\N	f
3056	Belarus 800	Belarus	800	1977	85	\N	3039	27.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1443.webp	f	\N	f
3057	Belarus 802	Belarus	802	1990	85	\N	3356	27.4	4x2	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1444.webp	f	\N	f
3058	Belarus 805	Belarus	805	1983	100	\N	3900	27.6	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1445.webp	t	\N	f
3059	Belarus 820	Belarus	820	1977	85	\N	3243	27.4	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1446.webp	f	\N	f
3060	Belarus 822	Belarus	822	1984	85	\N	3569	27.4	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1447.webp	f	\N	f
3061	Belarus 825	Belarus	825	1983	100	\N	4127	27.6	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1448.webp	t	\N	f
210	John Deere 4755	John Deere	4755	1989	187.7	\N	7348	95.5	4x4	Diagonal 20.8-38	528	1863	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td145.webp	t	\N	f
331	John Deere M	John Deere	M	1947	20	\N	1179	10.4	4x2	Diagonal 8-24	203	955	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td31.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1064/	f
1643	New Holland TC40	New Holland	TC40	2001	40	\N	1427	12.8	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3100.webp	f	\N	f
1644	New Holland TC45	New Holland	TC45	2001	45	\N	1626	14.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3101.webp	f	\N	f
1645	New Holland TC48DA	New Holland	TC48DA	2003	48	\N	1957	15	4x4	Diagonal 14.9-24	378	1253	\N	\N	12.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3102.webp	f	\N	f
1646	New Holland TC55DA	New Holland	TC55DA	2003	55	\N	1922	17.6	4x4	Diagonal 14.9-24	378	1253	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3103.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1250/	f
1647	New Holland TN55	New Holland	TN55	1999	53	\N	2286	28.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	10.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3104.webp	f	\N	f
1648	New Holland TN65	New Holland	TN65	1998	57	\N	2331	30.2	4x4	Diagonal 14.9-28	378	1355	\N	\N	12.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3105.webp	f	\N	f
1685	New Holland TT55	New Holland	TT55	2002	55	\N	2220	17.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/20190218170833_TT55_alta-700x700.jpg	t	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/tt-75.pdf	t
3066	Belarus 922	Belarus	922	1984	100	\N	3569	32.3	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1453.webp	t	\N	f
1649	New Holland TL70	New Holland	TL70	1999	65	\N	3089	40.3	4x4	Diagonal 99 - 20	2515	4783	\N	\N	14	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3106.webp	f	\N	f
211	John Deere 8560	John Deere	8560	1989	235	\N	14549	143.1	4x4	Diagonal 89 - 19	2261	4326	\N	\N	44.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td146.webp	t	\N	f
1650	New Holland TN70	New Holland	TN70	2000	69	\N	2342	32.8	4x4	Diagonal 14.9-28	378	1355	\N	\N	13.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3107.webp	t	\N	f
1651	New Holland TN75	New Holland	TN75	1999	75	\N	2347	29.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3108.webp	t	\N	f
1654	New Holland TN90F	New Holland	TN90F	1997	91.1	\N	2699	29.4	4x4	Radial 420/70R28	420	1299	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3111.webp	t	\N	f
1656	New Holland TS90	New Holland	TS90	1999	90	\N	3749	45.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	17.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3113.webp	f	\N	f
1658	New Holland TS110	New Holland	TS110	1999	110	\N	3774	46.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3115.webp	t	\N	f
1660	New Holland 9184	Versatile	holland 9184	2000	240	\N	7766	111.3	4x4	Diagonal 18.4-38	467	1760	\N	\N	55.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3120.webp	t	\N	f
1661	New Holland 9384	Versatile	holland 9384	2000	270	\N	8547	99.1	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3121.webp	t	\N	f
1667	New Holland TJ450	New Holland	TJ450	2002	450	\N	17837	198.1	4x4	Radial 18.4R46	467	1963	\N	\N	86.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3128.webp	t	\N	f
1668	New Holland TG210	New Holland	holland tg210	2003	210	\N	8882	89.4	4x4	Radial 20.8R42	528	1965	\N	\N	43.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3130.webp	t	\N	f
1669	New Holland TG230	New Holland	holland tg230	2002	230	\N	8882	88.2	4x4	Radial 20.8R42	528	1965	\N	\N	46.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3131.webp	t	\N	f
1670	New Holland TG255	New Holland	holland tg255	2002	255	\N	9162	91.8	4x4	Radial 20.8R42	528	1965	\N	\N	51.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3132.webp	t	\N	f
1671	New Holland TG285	New Holland	holland tg285	2002	285	\N	9162	92.3	4x4	Radial 20.8R42	528	1965	\N	\N	56	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3133.webp	t	\N	f
1672	New Holland TV140	New Holland	TV140	1998	140	\N	6674	49	4x4	Diagonal 16.9-28	429	1441	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3134.webp	t	\N	f
1674	New Holland TM120	New Holland	TM120	2002	120	\N	5379	54.8	4x4	Radial 18.4R38	467	1760	\N	\N	24.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3136.webp	t	\N	f
1675	New Holland TM130	New Holland	TM130	2002	130	\N	5379	55.8	4x4	Radial 18.4R38	467	1760	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3137.webp	t	\N	f
1676	New Holland TM140	New Holland	TM140	2002	140	\N	5410	61.8	4x4	Radial 18.4R38	467	1760	\N	\N	28.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3138.webp	t	\N	f
1677	New Holland TM155	New Holland	TM155	2002	155	\N	5642	61.9	4x4	Radial 18.4R38	467	1760	\N	\N	31	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3139.webp	t	\N	f
1678	New Holland TM175	New Holland	TM175	2002	175	\N	6967	59	4x4	Radial 20.8R42	528	1965	\N	\N	34.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3140.webp	t	\N	f
1679	New Holland TM190	New Holland	TM190	2002	190	\N	6967	77.7	4x4	Radial 20.8R42	528	1965	\N	\N	36.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3141.webp	t	\N	f
1652	New Holland TL80	New Holland	TL80	1999	80	\N	3200	40.9	4x4	Diagonal 99 - 20	2515	4783	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3109.webp	t	\N	f
1653	New Holland TL90	New Holland	TL90	1999	90	\N	3400	41.3	4x4	Diagonal 99 - 20	2515	4783	\N	\N	17.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3110.webp	t	\N	f
1655	New Holland TN95F	New Holland	TN95F	2002	90	\N	3100	29.4	4x4	Diagonal 02 - 20	51	594	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3112.webp	t	\N	f
1657	New Holland TL100	New Holland	TL100	1999	95	\N	3400	42.4	4x4	Diagonal 99 - 20	2515	4783	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3114.webp	t	\N	f
1659	New Holland TS100	New Holland	TS100	1999	100	\N	3749	43.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	19.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3116.webp	t	\N	f
1673	New Holland TV145	New Holland	TV145	2004	145	\N	6674	49	4x4	Diagonal 04 - 20	102	681	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3135.webp	t	\N	f
223	John Deere 4010	Yanmar	deere 4010	2002	18.5	\N	644	5.1	4x4	Diagonal 29x12.50-15	318	737	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1550.webp	f	\N	f
224	John Deere 4110	Yanmar	deere 4110	2002	20	\N	688	6.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1551.webp	f	\N	f
225	John Deere 4115	Yanmar	deere 4115	2002	24	\N	803	7.3	4x4	Diagonal 35x12.00	889	1816	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1552.webp	f	\N	f
226	John Deere 4210	John Deere	4210	2002	27	\N	1213	8.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1553.webp	f	\N	f
227	John Deere 4310	John Deere	4310	2002	31.2	\N	1315	9.9	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1554.webp	f	\N	f
228	John Deere 4410	John Deere	4410	2002	34.6	\N	254	11	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1555.webp	f	\N	f
1688	New Holland TB110	New Holland	TB110	2003	110	\N	3166	33	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3150.webp	t	\N	f
1690	New Holland TK80	New Holland	TK80	2004	77	\N	3837	24.2	track	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3152.webp	f	\N	f
1686	New Holland TT75	New Holland	TT75	2002	74	\N	2480	21.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://cdn11.bigcommerce.com/s-xeihv17pvg/images/stencil/1280w/products/216/2396/New_Holland-New_Holland_TT75_Doble_Traccion-lateral__78296.1706029614.png?c=1	t	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/tt-75.pdf	t
1691	New Holland TK100	New Holland	TK100	2004	93	\N	4037	29.4	track	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3153.webp	t	\N	f
3316	J.I. Case 10-18	Case IH	10 18	1918	18	\N	1705	7.7	4x2	Diagonal 42x9	1067	2042	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3178.webp	f	\N	f
335	John Deere 7710	John Deere	7710	1997	155	\N	6414	83	4x4	Diagonal 18.4-38	467	1760	\N	\N	31.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3210.webp	t	\N	f
337	John Deere 7410	John Deere	7410	1997	120	\N	5598	59.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3212.webp	t	\N	f
338	John Deere 7510	John Deere	7510	1999	135	\N	5598	69.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	25	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3213.webp	t	\N	f
345	John Deere 8300	John Deere	8300	1995	200	\N	8402	113.8	4x4	Radial 18.4R46	467	1963	\N	\N	45.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3226.webp	t	\N	f
347	John Deere 8400	John Deere	8400	1995	225	\N	8486	130.1	4x4	Radial 18.4R46	467	1963	\N	\N	49.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3228.webp	t	\N	f
349	John Deere 9100	John Deere	9100	1997	260	\N	12873	150.9	4x4	Radial 20.8R38	528	1863	\N	\N	50	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3230.webp	t	\N	f
350	John Deere 9200	John Deere	9200	1996	310	\N	14068	151.5	4x4	Radial 20.8R42	528	1965	\N	\N	61.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3231.webp	t	\N	f
351	John Deere 9300	John Deere	9300	1997	360	\N	14261	110.8	4x4	Radial 620/70R42	620	1935	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3232.webp	t	\N	f
336	John Deere 7210	John Deere	7210	1997	110	\N	5598	59	4x4	Diagonal 18.4-38	467	1760	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3211.webp	t	\N	f
352	John Deere 6410	John Deere	6410	1999	104	\N	3740	42.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3233.webp	t	\N	f
353	John Deere 6210	John Deere	6210	1999	90	\N	3590	47.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	17	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3234.webp	t	\N	f
354	John Deere 6310	John Deere	6310	1999	99	\N	3630	41.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3235.webp	t	\N	f
346	John Deere 8310	John Deere	8310	1999	205	\N	8402	75.2	track	Diagonal 99 - 20	2515	4783	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3227.webp	t	\N	f
356	John Deere 6510L	John Deere	6510L	1999	114	\N	3800	34.9	4x4	Diagonal 18.4-26	467	1455	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3247.webp	t	\N	f
357	John Deere 6500L	John Deere	6500L	1994	114	\N	3800	34.9	4x4	Diagonal 18.4-26	467	1455	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3248.webp	t	\N	f
1694	Kubota B7000	Kubota	B7000	1973	12.8	\N	476	4.7	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3252.webp	f	\N	f
1695	Kubota B7001	Kubota	B7001	1976	13.8	\N	476	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3253.webp	f	\N	f
358	John Deere 4300	John Deere	4300	1998	32.2	\N	254	9.9	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3298.webp	f	\N	f
1697	Kubota BX2200	Kubota	BX2200	2001	22	\N	725	6.1	4x4	Diagonal 26x12.0	660	1427	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3356.webp	f	\N	f
3317	Zetor 5911	Zetor	5911	1977	58	\N	2950	21.3	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3360.webp	f	\N	f
348	John Deere 8410	John Deere	8410	1999	235	\N	9271	133.8	4x4	Diagonal 99 - 20	2515	4783	\N	\N	53.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3229.webp	t	\N	f
355	John Deere 1120	John Deere	1120	1967	53	\N	3501	16.5	4x2	Diagonal 11-36	279	1389	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3239.webp	f	\N	f
1696	New Holland TN60A	New Holland	TN60A	2004	57	\N	2449	27.3	4x4	Diagonal 04 - 20	102	681	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3254.webp	f	\N	f
260	John Deere 6320	John Deere	6320	2002	100	\N	4549	42	4x2	Diagonal 18.4-34	467	1658	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1585.webp	t	\N	f
261	John Deere 6420	John Deere	6420	2002	110	\N	4565	44.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1586.webp	t	\N	f
1700	CaseIH MX245 Magnum	CaseIH	MX245 Magnum	2006	248	\N	9609	89.5	4x4	Diagonal 06 - 20	152	767	\N	\N	47.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3403.webp	t	\N	f
1701	CaseIH MX275 Magnum	CaseIH	MX275 Magnum	2006	275	\N	9784	99.6	4x4	Diagonal 06 - 20	152	767	\N	\N	57.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3404.webp	t	\N	f
1702	CaseIH MX305 Magnum	CaseIH	MX305 Magnum	2006	304	\N	9790	90.6	4x4	Diagonal 06 - 20	152	767	\N	\N	64.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3405.webp	t	\N	f
265	John Deere 5300	John Deere	5300	1992	55.9	\N	2249	23.1	4x4	Diagonal 14.9-28	378	1355	\N	\N	11.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td159.webp	f	\N	f
270	John Deere 8120	John Deere	8120	2002	208	\N	8663	99.2	4x4	Radial 480/80R46	480	1936	\N	\N	39.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1594.webp	t	\N	f
373	John Deere 6230	John Deere	6230	2007	95	\N	3892	27.5	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3412.webp	t	\N	f
3318	Zetor 5945	Zetor	5945	1977	58	\N	3380	21.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3361.webp	f	\N	f
3319	Zetor 6911	Zetor	6911	1977	65	\N	2950	23.8	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3362.webp	f	\N	f
3320	Zetor 6945	Zetor	6945	1977	65	\N	3380	23.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3363.webp	f	\N	f
3321	Fiat 35-66	Fiat	35 66	1990	34.5	\N	1400	12.7	4x4	Radial 320/70R28	320	1159	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3377.webp	f	\N	f
3322	Fiat 45-66	Fiat	45 66	1985	44.4	\N	2150	16.3	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3378.webp	f	\N	f
3324	Fiat 60-66	Fiat	60 66	1984	59.2	\N	2860	21.7	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3380.webp	f	\N	f
3325	Fiat 65-66	Fiat	65 66	1985	64.1	\N	3035	23.5	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3381.webp	f	\N	f
3326	Fiat 70-66	Fiat	70 66	1984	69	\N	3150	25.3	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3382.webp	f	\N	f
1698	Kubota B7800	Kubota	B7800	2003	30	\N	789	8.1	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3386.webp	f	\N	f
360	Massey Ferguson 4325	Massey Ferguson	ferguson 4325	2002	67	\N	2957	34.2	4x4	Radial 480/70R34	480	1536	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3387.webp	f	\N	f
361	Massey Ferguson 4335	Massey Ferguson	ferguson 4335	2001	78	\N	2969	31	4x4	Radial 480/70R34	480	1536	\N	\N	16.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3388.webp	f	\N	f
362	Massey Ferguson 4345	Massey Ferguson	ferguson 4345	2001	90	\N	2969	39.8	4x4	Radial 480/70R34	480	1536	\N	\N	17.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3389.webp	t	\N	f
3327	J.I. Case 15-27	Case IH	15 27	1919	27	\N	2930	15.3	4x2	Diagonal 52x14	1321	2601	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3396.webp	f	\N	f
369	John Deere 7630	John Deere	7630	2007	175	\N	7770	59.4	4x4	Radial 480/80R42	480	1835	\N	\N	33.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3408.webp	t	\N	f
370	John Deere 7730	John Deere	7730	2007	190	\N	7757	63.3	4x4	Radial 480/80R42	480	1835	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3409.webp	t	\N	f
262	John Deere 7220	John Deere	7220	2003	110	\N	5366	52.6	4x4	Diagonal 03 - 20	76	638	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1587.webp	t	\N	f
263	John Deere 7320	John Deere	7320	2003	125	\N	5899	58.4	4x4	Diagonal 03 - 20	76	638	\N	\N	24.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1588.webp	t	\N	f
264	John Deere 7420	John Deere	7420	2003	135	\N	5846	46.7	4x4	Diagonal 03 - 20	76	638	\N	\N	25.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1589.webp	t	\N	f
271	John Deere 8220	John Deere	8220	2002	233	\N	8663	106.2	4x4	Diagonal 02 - 20	51	594	\N	\N	43.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1595.webp	t	\N	f
374	John Deere 6330	John Deere	6330	2007	105	\N	4536	29.7	4x2	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3413.webp	t	\N	f
371	John Deere 7830	John Deere	7830	2007	205	\N	8042	69.4	4x4	Radial 480/80R46	480	1936	\N	\N	39.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3410.webp	t	\N	f
372	John Deere 7930	John Deere	7930	2007	220	\N	8042	74.6	4x4	Radial 480/80R46	480	1936	\N	\N	43.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3411.webp	t	\N	f
1492	CaseIH JX75 Maxxima	Turk Tractor	jx75	2002	75	\N	3073	17.5	4x4	Diagonal 02 - 20	51	594	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1622.webp	f	\N	f
1489	CaseIH Farmall DX55	CaseIH	Farmall DX55	2004	55	\N	2204	17.6	4x4	Diagonal 04 - 20	102	681	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1619.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1250/	f
283	John Deere 7700	John Deere	7700	1993	150	\N	7033	77.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	28.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td162.webp	t	\N	f
375	John Deere 6430	John Deere	6430	2007	120	\N	4536	45	4x2	Diagonal 07 - 20	178	810	\N	\N	25.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3414.webp	t	\N	f
377	John Deere 3203	John Deere	3203	2006	32	\N	400	8.8	4x4	Diagonal 15-19.5	381	1143	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3416.webp	f	\N	f
1490	CaseIH JX55 Maxxima	Turk Tractor	jx55	2002	58	\N	3041	16.5	4x4	Diagonal 02 - 20	51	594	\N	\N	11	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1620.webp	f	\N	f
376	John Deere 5403	John Deere	5403	2007	74	\N	2323	24.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	14.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3415.webp	t	\N	f
378	John Deere 1840	John Deere	1840	1979	70	\N	2483	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3424.webp	f	\N	f
3330	Fiat M135	Fiat	M135	1996	135	\N	5368	43.7	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3450.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1113/	f
3331	Fiat M160	Fiat	M160	1996	160	\N	5618	52.5	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3451.webp	t	\N	f
379	John Deere 50	John Deere	50	1952	30.97	\N	2202	15.6	4x2	Diagonal 10-38	254	1397	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td35.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1070/	f
380	Massey Ferguson 140	Massey Ferguson	140	1966	43	\N	1450	15.8	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3572.webp	f	\N	f
381	Massey Ferguson 145	Massey Ferguson	145	2000	47	\N	1650	17.2	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3577.webp	f	\N	f
1703	CaseIH C42	Steyr	c42	1992	42	\N	2360	15.4	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3594.webp	f	\N	f
1704	CaseIH C48	Steyr	c48	1992	48	\N	2380	17.6	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3595.webp	t	\N	f
1705	CaseIH C55	Steyr	c55	1992	55	\N	2810	20.2	4x2	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3596.webp	f	\N	f
1706	CaseIH C64	Steyr	c64	1992	64	\N	2930	23.5	4x2	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3597.webp	t	\N	f
1707	CaseIH C70	Steyr	c70	1992	70	\N	2930	25.7	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3598.webp	t	\N	f
1708	CaseIH CS 48	CaseIH	CS 48	1996	48	\N	2710	17.6	4x4	Radial 14.9R28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3599.webp	f	\N	f
382	John Deere 60	John Deere	60	1952	41.57	\N	2404	19.4	4x2	Diagonal 11-38	279	1440	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td36.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1069/	f
1709	CaseIH CS 58	CaseIH	CS 58	1996	58	\N	2750	21.3	4x4	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3600.webp	t	\N	f
384	John Deere 70	John Deere	70	1953	50.35	\N	2965	24.3	4x2	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td37.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1072/	f
385	John Deere 2300	Zetor	deere 2300	1993	69	\N	3025	24.1	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3709.webp	f	\N	f
386	John Deere 2400	Zetor	deere 2400	1993	78	\N	3519	26.1	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3710.webp	t	\N	f
1723	Kubota B7400	Kubota	B7400	2000	16	\N	585	4.6	4x4	Diagonal 8.3-16	211	765	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3723.webp	f	\N	f
1724	Kubota B7500	Kubota	B7500	2000	21	\N	620	6.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3724.webp	f	\N	f
1491	CaseIH JX65 Maxxima	Turk Tractor	jx65	2002	65	\N	2780	16.4	4x4	Diagonal 02 - 20	51	594	\N	\N	11.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1621.webp	f	\N	f
1726	CaseIH Puma 180	CaseIH	Puma 180	2007	180	\N	7125	74.7	4x2	Radial 20.8R42	528	1965	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3765.webp	t	\N	f
1727	CaseIH Puma 195	CaseIH	Puma 195	2007	195	\N	7125	69.5	4x2	Radial 20.8R42	528	1965	\N	\N	41.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3766.webp	t	\N	f
1728	CaseIH Puma 210	CaseIH	Puma 210	2007	210	\N	7125	69.5	4x4	Radial 20.8R42	528	1965	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3767.webp	t	\N	f
1520	CaseIH STX450	CaseIH	STX450	2002	450	\N	17837	198.1	4x4	Diagonal 02 - 20	51	594	\N	\N	86.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1650.webp	t	\N	f
1521	CaseIH STX500	CaseIH	STX500	2004	500	\N	24494	161.4	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1651.webp	t	\N	f
1522	CaseIH STX375QT Quadtrac	CaseIH	STX375QT Quadtrac	2002	375	\N	24160	121.1	track	Diagonal 02 - 20	51	594	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1652.webp	t	\N	f
1523	CaseIH STX425QT Quadtrac	CaseIH	STX425QT Quadtrac	2002	425	\N	24160	135.7	track	Diagonal 02 - 20	51	594	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1653.webp	t	\N	f
1524	CaseIH STX450QT Quadtrac	CaseIH	STX450QT Quadtrac	2002	450	\N	23285	170.9	track	Diagonal 02 - 20	51	594	\N	\N	84.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1654.webp	t	\N	f
1525	CaseIH STX500QT Quadtrac	CaseIH	STX500QT Quadtrac	2004	500	\N	24160	161.4	track	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1655.webp	t	\N	f
387	John Deere 40	John Deere	40	1953	21.13	\N	1315	13.4	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td38.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1073/	f
3335	Challenger MT425	Challenger	mt425	2002	55	\N	2957	34.2	4x4	Radial 18.4R30	467	1557	\N	\N	14	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3813.webp	f	\N	f
3336	Challenger MT425B	Challenger	mt425b	2004	75	\N	4316	37.3	4x4	Radial 18.4R34	467	1658	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3814.webp	f	\N	f
3337	Challenger MT445	Challenger	mt445	2002	65	\N	2969	31	4x4	Radial 13.6R38	345	1552	\N	\N	16.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3815.webp	f	\N	f
3339	Challenger MT455	Challenger	mt455	2002	75	\N	2969	39.8	4x4	Radial 18.4R34	467	1658	\N	\N	18.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3817.webp	t	\N	f
3341	Challenger MT465	Challenger	mt465	2002	85	\N	3386	40.8	4x4	Radial 18.4R38	467	1760	\N	\N	19.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3819.webp	t	\N	f
3343	Challenger MT525B	Challenger	mt525b	2004	118	\N	5237	45.2	4x4	Radial 18.4R38	467	1760	\N	\N	24.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3821.webp	t	\N	f
3348	Challenger MT565	Challenger	mt565	2002	145	\N	7468	62	4x4	Radial 20.8R42	528	1965	\N	\N	34.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3826.webp	t	\N	f
3349	Challenger MT635	Challenger	mt635	2002	160	\N	8573	64.1	4x4	Radial 18.4R42	467	1861	\N	\N	37.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3827.webp	t	\N	f
3350	Challenger MT635B	Challenger	mt635b	2005	215	\N	8304	75.3	4x4	Radial 480/80R46	480	1936	\N	\N	40.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3828.webp	t	\N	f
3351	Challenger MT645	Challenger	mt645	2002	180	\N	8618	67.7	4x4	Radial 18.4R42	467	1861	\N	\N	40.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3829.webp	t	\N	f
3352	Challenger MT645B	Challenger	mt645b	2005	235	\N	8304	75.4	4x4	Radial 480/80R46	480	1936	\N	\N	44.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3830.webp	t	\N	f
3353	Challenger MT655	Challenger	mt655	2002	200	\N	9752	92.4	4x4	Radial 650/85R38	650	2070	\N	\N	46.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3831.webp	t	\N	f
3354	Challenger MT655B	Challenger	mt655b	2005	260	\N	8867	109.5	4x4	Radial 480/80R46	480	1936	\N	\N	51.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3832.webp	t	\N	f
3355	Challenger MT665	Challenger	mt665	2002	225	\N	9752	93.1	4x4	Radial 650/85R38	650	2070	\N	\N	51.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3833.webp	t	\N	f
3356	Challenger MT665B	Challenger	mt665b	2005	290	\N	8867	120.4	4x4	Radial 480/80R46	480	1936	\N	\N	55.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3834.webp	t	\N	f
291	John Deere 8770	John Deere	8770	1993	300	\N	14950	148.9	4x4	Diagonal 93 - 19	2362	4498	\N	\N	58.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td170.webp	t	\N	f
399	Massey Ferguson 1547	Iseki	ferguson 1547	2005	47	\N	1631	13.9	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3864.webp	f	\N	f
3121	Zetor 7245	Zetor	7245	1985	64.6	\N	3356	28.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	13.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td1699.webp	f	\N	f
3370	Challenger MT345B	Agritalia	mt345b	2006	91	\N	2600	27.5	4x4	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3896.webp	t	\N	f
410	Massey Ferguson 1455	Iseki	ferguson 1455	2002	55.3	\N	1719	16.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3875.webp	f	\N	f
411	Massey Ferguson 825	Massey Ferguson	825	1963	25	\N	1179	8.9	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3881.webp	f	\N	f
3364	Challenger MT565B	Challenger	mt565b	2004	168	\N	4599	57.8	4x4	Radial 480/80R42	480	1835	\N	\N	34.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3890.webp	t	\N	f
3365	Challenger MT555B	Challenger	mt555b	2004	153	\N	4599	56.5	4x4	Radial 480/80R42	480	1835	\N	\N	32.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3891.webp	t	\N	f
3366	Challenger MT975B	Challenger	mt975b	2007	570	\N	18038	205	4x4	Radial 800/70R38	800	2085	\N	\N	124.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3892.webp	t	\N	f
3367	Challenger MT965B	Challenger	mt965b	2007	510	\N	18038	232.7	4x4	Radial 800/70R38	800	2085	\N	\N	107.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3893.webp	t	\N	f
3368	Challenger MT955B	Challenger	mt955b	2007	460	\N	17811	227.6	4x4	Radial 710/70R42	710	2061	\N	\N	98.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3894.webp	t	\N	f
3369	Challenger MT945B	Challenger	mt945b	2007	430	\N	17811	221.3	4x4	Radial 710/70R42	710	2061	\N	\N	90.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3895.webp	t	\N	f
413	Massey Ferguson 8450	Massey Ferguson	8450	2004	215	\N	8680	88.1	4x4	Radial 18.4R46	467	1963	\N	\N	42.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3902.webp	t	\N	f
417	Massey Ferguson 7465	Massey Ferguson	7465	2004	118	\N	6729	39.1	4x4	Radial 18.4R38	467	1760	\N	\N	23.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3906.webp	t	\N	f
418	Massey Ferguson 7475	Massey Ferguson	7475	2004	133	\N	6729	43.3	4x4	Radial 18.4R38	467	1760	\N	\N	27.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3907.webp	t	\N	f
419	Massey Ferguson 7480	Massey Ferguson	7480	2004	143	\N	6729	46.1	4x4	Radial 18.4R38	467	1760	\N	\N	29.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3908.webp	t	\N	f
420	Massey Ferguson 7485	Massey Ferguson	7485	2004	153	\N	6869	50.7	4x4	Radial 18.4R38	467	1760	\N	\N	29.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3909.webp	t	\N	f
421	Massey Ferguson 7490	Massey Ferguson	7490	2004	168	\N	6869	56.6	4x4	Radial 18.4R38	467	1760	\N	\N	33.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3910.webp	t	\N	f
422	Massey Ferguson 7495	Massey Ferguson	7495	2004	183	\N	7649	61.9	4x4	Radial 18.4R38	467	1760	\N	\N	36	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3911.webp	t	\N	f
424	Massey Ferguson 6475	Massey Ferguson	6475	2004	133	\N	5239	41.6	4x4	Radial 18.4R38	467	1760	\N	\N	25.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3913.webp	t	\N	f
1733	Ford 940	Ford	940	1954	40	\N	1487	14.7	4x2	Diagonal 12x28	305	1229	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3918.webp	f	\N	f
429	Massey Ferguson 5435	Massey Ferguson	5435	2004	75	\N	4234	22.6	4x4	Radial 18.4R34	467	1658	\N	\N	15.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3919.webp	f	\N	f
430	Massey Ferguson 5445	Massey Ferguson	5445	2004	85	\N	4220	38.6	4x4	Radial 480/70R38	480	1637	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3920.webp	t	\N	f
3371	Challenger MT335B	Agritalia	mt335b	2006	78	\N	2600	23.8	4x4	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3897.webp	t	\N	f
3372	Challenger MT325B	Agritalia	mt325b	2006	68	\N	2600	20.2	4x4	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3898.webp	t	\N	f
3373	Challenger MT315B	Agritalia	mt315b	2006	57.6	\N	2600	16.5	4x4	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td3899.webp	t	\N	f
412	John Deere 7530 Premium	John Deere	7530 Premium	2007	180	\N	6622	68.2	4x4	Diagonal 07 - 20	178	810	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td39.webp	t	\N	f
425	Massey Ferguson 6480	Massey Ferguson	6480	2004	143	\N	5013	45.5	4x4	Diagonal 04 - 20	102	681	\N	\N	28.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3914.webp	t	\N	f
426	Massey Ferguson 6485	Massey Ferguson	6485	2004	153	\N	6475	65.3	4x4	Diagonal 04 - 20	102	681	\N	\N	28	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3915.webp	t	\N	f
427	Massey Ferguson 6490	Massey Ferguson	6490	2004	168	\N	6475	67.3	4x4	Diagonal 04 - 20	102	681	\N	\N	31	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3916.webp	t	\N	f
428	Massey Ferguson 6495	Massey Ferguson	6495	2004	183	\N	6475	67.8	4x4	Diagonal 04 - 20	102	681	\N	\N	34.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3917.webp	t	\N	f
432	Massey Ferguson 5465	Massey Ferguson	5465	2004	109	\N	4774	39.9	4x4	Diagonal 04 - 20	102	681	\N	\N	23.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3923.webp	t	\N	f
438	Massey Ferguson 563	Massey Ferguson	563	2006	64	\N	2474	20.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3930.webp	t	\N	f
439	Massey Ferguson 573	Massey Ferguson	573	2006	72	\N	2530	24.3	4x2	Diagonal 16.9-30	429	1492	\N	\N	16.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3931.webp	f	\N	f
1734	Kubota B5001	Kubota	B5001	1976	9.4	\N	400	2.9	4x4	Diagonal 7-14	178	658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3938.webp	f	\N	f
445	John Deere 4235	John Deere	4235	1974	100	\N	5021	36.7	4x2	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3940.webp	f	\N	f
448	John Deere 2735	John Deere	2735	1975	61.7	\N	3129	22.6	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3944.webp	f	\N	f
449	Massey Ferguson 3080	Massey Ferguson	3080	1986	95.7	\N	4399	35.1	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3945.webp	f	\N	f
1735	New Holland TD75D	Turk Traktor	holland td75d	2002	72	\N	2586	22.7	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3970.webp	f	\N	f
1736	New Holland TD95D	Turk Traktor	holland td95d	2002	90	\N	2770	29.4	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3971.webp	t	\N	f
451	Massey Ferguson 1233	Iseki	ferguson 1233	2001	28.4	\N	899	9	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4002.webp	f	\N	f
1741	Ford TW-5	Ford	TW 5	1983	125	\N	5136	54.5	4x4	Diagonal 20.8x38	528	1863	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4033.webp	f	\N	f
1742	Ford TW-35	Ford	TW 35	1983	192	\N	6849	75.9	4x4	Diagonal 20.8x38	528	1863	\N	\N	39	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4034.webp	t	\N	f
453	John Deere 840	John Deere	840	1976	37.5	\N	2269	12.3	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4057.webp	f	\N	f
454	John Deere 940	John Deere	940	1980	42.9	\N	2269	14.3	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4058.webp	f	\N	f
455	John Deere 1040	John Deere	1040	1980	53.6	\N	2770	15.7	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4059.webp	f	\N	f
456	John Deere 1140	John Deere	1140	1980	55	\N	2404	18.2	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4060.webp	f	\N	f
457	John Deere 3045B	John Deere	3045B	2000	45	\N	1999	14	4x4	Diagonal 11.2-28	284	1195	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4077.webp	f	\N	f
1743	Kubota L3000	Kubota	L3000	2000	32.1	\N	1099	10.1	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4084.webp	f	\N	f
1744	Ford 4830	Ford	4830	1990	65	\N	3400	23.8	4x4	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4086.webp	f	\N	f
458	John Deere 80	John Deere	80	1955	57.49	\N	3764	32.9	4x2	Diagonal 15-34	381	1511	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td41.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1098/	f
459	Massey Ferguson 377	Massey Ferguson	377	1987	62	\N	3500	22.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4123.webp	f	\N	f
460	Massey Ferguson 387	Massey Ferguson	387	1987	71	\N	3640	26	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4124.webp	f	\N	f
461	Massey Ferguson 397	Massey Ferguson	397	1987	80	\N	3640	29.4	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4125.webp	f	\N	f
462	Massey Ferguson 353	Massey Ferguson	353	1987	48.3	\N	2800	17.7	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4126.webp	f	\N	f
463	Massey Ferguson 363	Massey Ferguson	363	1987	57.7	\N	2885	21.2	4x4	Diagonal 14.9-30	378	1405	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4127.webp	t	\N	f
464	Massey Ferguson 373	Massey Ferguson	373	1987	61.7	\N	3100	22.6	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4128.webp	f	\N	f
466	Massey Ferguson 273	Massey Ferguson	273	1983	59	\N	2700	21.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4130.webp	f	\N	f
434	Massey Ferguson 5470SA	Massey Ferguson	5470SA	2004	115	\N	4195	34.9	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3926.webp	t	\N	f
435	Massey Ferguson 5475SA	Massey Ferguson	5475SA	2004	125	\N	4195	38.5	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3927.webp	t	\N	f
436	Massey Ferguson 533	Massey Ferguson	533	2006	52	\N	1960	16.1	4x2	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3928.webp	f	\N	f
437	Massey Ferguson 543	Massey Ferguson	543	2006	52	\N	2250	16.5	4x2	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3929.webp	f	\N	f
444	John Deere 4435	John Deere	4435	1973	125	\N	5624	44	4x2	Diagonal 73 - 19	1854	3635	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3939.webp	t	\N	f
446	John Deere 920	John Deere	920	1967	37	\N	1973	12.1	4x2	Diagonal 9-36	229	1303	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3941.webp	f	\N	f
229	John Deere 3120 (1969-1972)	John Deere	3120	1969	86	\N	3500	25.7	4x2	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3942.webp	f	\N	f
447	John Deere 2535	John Deere	2535	1975	44.3	\N	2630	16.3	4x2	Diagonal 75 - 19	1905	3721	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3943.webp	f	\N	f
1738	New Holland TT50A	New Holland	TT50A	2007	48	\N	1695	15.4	4x2	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3973.webp	f	\N	f
1739	New Holland TT60A	New Holland	TT60A	2007	56	\N	2263	17.2	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3974.webp	f	\N	f
1740	New Holland TT75A	New Holland	TT75A	2007	75	\N	2357	22.7	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3975.webp	f	\N	f
452	John Deere 3155	John Deere	3155	1988	95	\N	4581	46.7	4x4	Diagonal 88 - 19	2235	4282	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4052.webp	f	\N	f
482	Massey Ferguson 194	Landini	ferguson 194	1977	75	\N	2980	27.5	4x4	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4146.webp	f	\N	f
301	John Deere 2140	John Deere	2140	1980	89.9	\N	3946	26.6	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1802.webp	t	\N	f
300	John Deere 1640	John Deere	1640	1979	62	\N	3630	19.8	4x4	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1801.webp	f	\N	f
479	Massey Ferguson 154	Landini	ferguson 154	1973	50	\N	2059	15.4	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4143.webp	f	\N	f
302	John Deere 710	John Deere	710	1966	50	\N	2295	18.3	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1805.webp	f	\N	f
303	John Deere 3040	John Deere	3040	1980	88.5	\N	4440	28.5	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1806.webp	f	\N	f
304	John Deere 4200	John Deere	4200	1998	26.3	\N	254	7.9	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td1809.webp	f	\N	f
1532	Kubota M5700	Kubota	M5700	2001	61.6	\N	1849	29.6	4x4	Diagonal 16.9-28	429	1441	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1827.webp	f	\N	f
1533	Kubota L3240	Kubota	L3240	2007	34	\N	1539	9.7	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1831.webp	f	\N	f
1534	Kubota L3540	Kubota	L3540	2007	37	\N	1495	10.8	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1832.webp	f	\N	f
467	Massey Ferguson 293	Massey Ferguson	293	1983	73.8	\N	2975	27.1	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4131.webp	f	\N	f
468	Massey Ferguson 254S	Landini	ferguson 254s	1983	56	\N	2120	20.5	4x2	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4132.webp	t	\N	f
469	Massey Ferguson 274S	Landini	ferguson 274s	1983	60	\N	2830	22	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4133.webp	f	\N	f
471	Massey Ferguson 284S	Landini	ferguson 284s	1983	66	\N	3240	24.2	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4135.webp	f	\N	f
472	Massey Ferguson 284SK	Massey Ferguson	284SK	1983	68	\N	3370	24.9	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4136.webp	f	\N	f
473	Massey Ferguson 294S	Landini	ferguson 294s	1983	75	\N	3350	27.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4137.webp	f	\N	f
474	Massey Ferguson 294SK	Massey Ferguson	294SK	1983	75	\N	3480	27.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4138.webp	f	\N	f
475	Massey Ferguson 1014	Landini	ferguson 1014	1978	95	\N	4526	34.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4139.webp	f	\N	f
476	Massey Ferguson 1024	Landini	ferguson 1024	1978	127	\N	5000	46.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4140.webp	f	\N	f
477	Massey Ferguson 1114	Landini	ferguson 1114	1978	110	\N	4850	40.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4141.webp	f	\N	f
478	Massey Ferguson 1134	Landini	ferguson 1134	1978	132	\N	5050	48.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4142.webp	t	\N	f
3374	Belarus LTZ-40	Belarus	LTZ 40	1968	50	\N	2750	18.3	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4194.webp	f	\N	f
3375	Belarus LTZ-400	Belarus	LTZ 400	1972	55	\N	2640	20.2	4x2	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4195.webp	f	\N	f
3376	Belarus LTZ-420	Belarus	LTZ 420	1972	55	\N	2770	20.2	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4196.webp	f	\N	f
3377	Belarus T-405	Belarus	T 405	1978	55	\N	3200	20.2	4x2	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4197.webp	f	\N	f
483	John Deere 520	John Deere	520	1956	37.52	\N	2249	20.7	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td42.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1080/	f
480	Massey Ferguson 174	Landini	ferguson 174	1973	65	\N	2209	23.8	4x2	Diagonal 13-30	330	1323	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4144.webp	f	\N	f
481	Massey Ferguson 184	Landini	ferguson 184	1980	68	\N	2490	31.6	4x2	Diagonal 14-30	356	1367	\N	\N	15.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4145.webp	f	\N	f
1560	Kubota L4400	Kubota	L4400	2004	45.3	\N	1430	13.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td1858.webp	f	\N	f
495	Massey Ferguson 550	Massey Ferguson	550	1977	47	\N	2082	15.6	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4712.webp	f	\N	f
484	Massey Ferguson 155	Massey Ferguson	155	1970	54	\N	2406	19.8	4x2	Diagonal 12x28	305	1229	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4204.webp	f	\N	f
3391	Belarus MTZ-82	Belarus	MTZ 82	1975	80	\N	3820	29.4	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4214.webp	f	\N	f
3393	Belarus MTZ-820	Belarus	MTZ 820	1977	80	\N	3855	29.4	4x4	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td4216.webp	f	\N	f
3399	J.I. Case D	Case IH	D	1939	35	\N	2086	12.8	4x2	Diagonal 12.75x24	324	1160	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td448.webp	f	\N	f
3400	J.I. Case DC	Case IH	DC	1939	37	\N	2404	18.4	4x2	Diagonal 11.25-36	286	1400	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td449.webp	f	\N	f
3401	J.I. Case L	Case IH	L	1929	45	\N	2407	19.9	4x2	Diagonal 13.5-28	343	1294	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td450.webp	f	\N	f
3402	J.I. Case LA	Case IH	LA	1940	58	\N	3408	29.6	4x2	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td451.webp	f	\N	f
3403	J.I. Case R	Case IH	R	1938	18	\N	1882	6.6	4x2	Diagonal 9.00-24	229	998	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td452.webp	f	\N	f
3404	J.I. Case RC	Case IH	RC	1935	17	\N	1834	6.2	4x2	Diagonal 10x38	254	1397	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td453.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1113/	f
3405	J.I. Case SC	Case IH	SC	1941	22	\N	1905	14.1	4x2	Diagonal 10x38	254	1397	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td454.webp	f	\N	f
3406	J.I. Case VA	Case IH	VA	1942	17	\N	1451	10.6	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td455.webp	f	\N	f
3407	J.I. Case 211-B	Case IH	211 B	1958	30	\N	1657	16.4	4x2	Diagonal 10-28	254	1143	\N	\N	10.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td457.webp	f	\N	f
3408	J.I. Case 300	Case IH	300	1956	27	\N	1542	9.9	4x2	Diagonal 11x24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td458.webp	f	\N	f
3409	J.I. Case 301	Case IH	301	1956	27	\N	1701	18.1	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td459.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1015/	f
3411	J.I. Case 310	Case IH	310	1956	29	\N	1451	10.6	4x2	Diagonal 11x24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td461.webp	f	\N	f
3412	J.I. Case 311	Case IH	311	1956	29	\N	1615	18.6	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td462.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1014/	f
3413	J.I. Case 350	Case IH	350	1958	42	\N	1939	15.4	4x2	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td463.webp	f	\N	f
3414	J.I. Case 351	Case IH	351	1958	42	\N	1741	15.4	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td464.webp	f	\N	f
3415	J.I. Case 400	Case IH	400	1955	50	\N	2721	18.3	4x2	Diagonal 13-30	330	1323	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td465.webp	f	\N	f
3416	J.I. Case 411-B	Case IH	411 B	1958	37	\N	1972	26.4	4x2	Diagonal 11-28	279	1186	\N	\N	13.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td470.webp	f	\N	f
497	Massey Ferguson 575	Massey Ferguson	575	1976	66	\N	3645	22.1	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4714.webp	f	\N	f
498	Massey Ferguson 590	Massey Ferguson	590	1977	75	\N	3551	24.8	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4715.webp	f	\N	f
3417	J.I. Case 430	Case IH	430	1960	34	\N	1417	12.5	4x2	Diagonal 11x24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td472.webp	f	\N	f
3418	J.I. Case 431	Case IH	431	1960	34	\N	1530	20	4x2	Diagonal 12.4x28	315	1247	\N	\N	7.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td473.webp	f	\N	f
3419	J.I. Case 440	Case IH	440	1960	33	\N	1417	12.1	4x2	Diagonal 11x24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td474.webp	f	\N	f
3420	J.I. Case 441	Case IH	441	1960	33	\N	1530	19.4	4x2	Diagonal 12.4x28	315	1247	\N	\N	10.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td475.webp	f	\N	f
496	Massey Ferguson 565	Massey Ferguson	565	1977	60	\N	2769	20.6	4x2	Diagonal 14-30	356	1367	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4713.webp	f	\N	f
3422	J.I. Case 500	Case IH	500	1953	55	\N	3628	33	4x2	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td477.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1126/	f
3424	J.I. Case 530	Case IH	530	1960	40	\N	1814	27.2	4x2	Diagonal 12.4-28	315	1247	\N	\N	9.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td479.webp	f	\N	f
499	John Deere 330	John Deere	330	1958	21.5	\N	1202	7.9	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td48.webp	f	\N	f
502	John Deere 303	John Deere	303	1963	36.3	\N	1740	13.3	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4826.webp	f	\N	f
3426	J.I. Case 611-B	Case IH	611 B	1958	45	\N	2215	24.3	4x2	Diagonal 12.4-36	315	1450	\N	\N	17.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td484.webp	f	\N	f
507	John Deere 2251	John Deere	2251	1987	61.7	\N	3402	22.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4841.webp	f	\N	f
3427	J.I. Case 630	Case IH	630	1960	50	\N	2086	32	4x2	Diagonal 16.9-28	429	1441	\N	\N	14.8	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td485.webp	f	\N	f
3428	J.I. Case 700	Case IH	700	1958	51	\N	3447	18.7	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td487.webp	f	\N	f
512	John Deere 430	John Deere	430	1958	28.31	\N	1474	16.9	4x2	Diagonal 10-34	254	1295	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td49.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1086/	f
3429	J.I. Case 730	Case IH	730	1960	56	\N	3175	20.5	4x2	Diagonal 14.9-30	378	1405	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td490.webp	f	\N	f
3430	J.I. Case 731	Case IH	731	1960	56.5	\N	3218	32.7	4x2	Diagonal 13.6-38	345	1552	\N	\N	16.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td491.webp	f	\N	f
3431	J.I. Case 741	Case IH	741	1960	57.92	\N	3175	33.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	19.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td492.webp	f	\N	f
3432	J.I. Case 770	Case IH	770	1969	56	\N	4182	31.6	4x2	Diagonal 16.9-34	429	1593	\N	\N	18.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td493.webp	f	\N	f
513	John Deere 4600	John Deere	4600	1998	43	\N	1564	13.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4948.webp	f	\N	f
3433	J.I. Case 801-B	Case IH	801 B	1958	54	\N	3084	35.1	4x2	Diagonal 15.5-38	394	1634	\N	\N	15.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td495.webp	f	\N	f
3434	J.I. Case 811-B	Case IH	811 B	1958	54	\N	3073	32.1	4x2	Diagonal 15.5-38	394	1634	\N	\N	17	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td497.webp	f	\N	f
3435	J.I. Case 830	Case IH	830	1960	66	\N	2582	24.2	4x2	Diagonal 13-30	330	1323	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td498.webp	f	\N	f
514	John Deere 1350	John Deere	1350	1986	37.5	\N	2431	13.8	4x2	Diagonal 9.5-36	241	1325	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4993.webp	f	\N	f
515	John Deere 1550	John Deere	1550	1987	43.4	\N	2884	15.9	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4994.webp	f	\N	f
523	John Deere 4350	John Deere	4350	1985	138	\N	6390	50.6	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5001.webp	t	\N	f
524	John Deere 4040S	John Deere	4040S	1981	115	\N	5021	42.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5002.webp	t	\N	f
525	John Deere 4240S	John Deere	4240S	1982	132	\N	5261	48.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5003.webp	t	\N	f
3436	J.I. Case 885	Case IH	885	1980	47.3	\N	1934	22.8	4x2	Diagonal 14.9-28	378	1355	\N	\N	10.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5004.webp	f	\N	f
526	Massey Ferguson 281XE	Massey Ferguson	281XE	2001	69	\N	2630	25.3	4x2	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5019.webp	f	\N	f
3437	J.I. Case 870	Case IH	870	1970	71	\N	4173	39.5	4x2	Diagonal 18.4-34	467	1658	\N	\N	17.8	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td502.webp	f	\N	f
1750	New Holland TC21DA	New Holland	holland tc21da	2003	21	\N	698	6.2	4x4	Diagonal 8x16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5020.webp	f	\N	f
527	John Deere 6510	John Deere	6510	1997	105	\N	4699	33.8	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5021.webp	f	\N	f
528	John Deere 6610	John Deere	6610	1997	114	\N	4717	37.1	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5022.webp	t	\N	f
529	John Deere 6810	John Deere	6810	1997	125	\N	5171	41.5	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5023.webp	t	\N	f
530	John Deere 6910	John Deere	6910	1997	140	\N	5171	45.9	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5024.webp	t	\N	f
501	John Deere 510	John Deere	510	1966	39.5	\N	2060	14.5	4x2	Diagonal 11-32	279	1288	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4825.webp	f	\N	f
505	John Deere 2541	John Deere	2541	1982	84.5	\N	2993	31	4x4	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4838.webp	t	\N	f
506	John Deere 2941	John Deere	2941	1982	95.2	\N	4279	34.9	4x4	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4839.webp	t	\N	f
508	John Deere 2351	John Deere	2351	1987	73.7	\N	3089	27	4x4	Diagonal 87 - 19	2210	4239	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4842.webp	f	\N	f
522	John Deere 3650	John Deere	3650	1986	114.4	\N	6128	38.4	4x4	Diagonal 70x38	1778	3988	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5000.webp	t	\N	f
1751	Kubota L2201	Kubota	L2201	1975	21.7	\N	820	8	4x4	Diagonal 8-22	203	904	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5028.webp	f	\N	f
3438	J.I. Case 900-B	Case IH	900 B	1957	70.24	\N	3855	41.8	4x2	Diagonal 15-34	381	1511	\N	\N	18.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td503.webp	f	\N	f
1752	New Holland TC29DA	New Holland	holland tc29da	2003	29	\N	1122	9.2	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5036.webp	f	\N	f
531	John Deere 62	John Deere	62	1937	10	\N	680	3.7	4x2	Diagonal 6x22	152	818	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5038.webp	f	\N	f
3439	Challenger MT475B	Challenger	mt475b	2008	120	\N	5400	53	4x4	Radial 420/85R38	420	1679	\N	\N	27.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5039.webp	t	\N	f
3440	J.I. Case 910-B	Case IH	910 B	1957	71.05	\N	3878	46.7	4x2	Diagonal 15-34	381	1511	\N	\N	26.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td504.webp	f	\N	f
1753	New Holland TC45A	New Holland	TC45A	2003	45	\N	1337	14.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5043.webp	f	\N	f
532	John Deere 4510	John Deere	4510	2002	38.4	\N	1564	12.1	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5048.webp	f	\N	f
3441	J.I. Case 930	Case IH	930	1960	83	\N	4014	48.8	4x2	Diagonal 15x34	381	1511	\N	\N	20.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td505.webp	f	\N	f
3442	J.I. Case 1394	Case IH	1394	1983	77	\N	3166	23.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5051.webp	t	\N	f
533	Massey Ferguson 2235	Massey Ferguson	2235	2002	80	\N	3099	29.4	4x4	Radial 480/70R24	480	1282	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5056.webp	f	\N	f
3445	J.I. Case 1494	Case IH	1494	1983	85	\N	3474	27.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5065.webp	t	\N	f
3446	J.I. Case 1594	Case IH	1594	1983	97	\N	4213	37	4x4	Diagonal 18.4-34	467	1658	\N	\N	19.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5069.webp	f	\N	f
1754	CaseIH 1694	CaseIH	1694	1985	112	\N	6123	36.3	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5068.webp	f	\N	f
3447	J.I. Case 1694	Case IH	1694	1983	112	\N	6123	36.3	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5071.webp	f	\N	f
3448	J.I. Case 970	Case IH	970	1970	86	\N	4558	47.2	4x2	Diagonal 18.4-38	467	1760	\N	\N	20.8	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td509.webp	f	\N	f
3449	J.I. Case 410-B	Case IH	410 B	1958	37	\N	1422	13.6	4x2	Diagonal 11-24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5094.webp	f	\N	f
3450	J.I. Case 510-B	Case IH	510 B	1958	45	\N	1735	16.5	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5095.webp	f	\N	f
536	Massey Ferguson 5710SL	Massey Ferguson	ferguson 5710sl	2016	95	\N	4799	34.9	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5103.webp	t	\N	f
3451	J.I. Case 310-B	Case IH	310 B	1958	37	\N	1323	13.6	4x2	Diagonal 11-24	279	1085	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5105.webp	f	\N	f
3452	J.I. Case 311-B	Case IH	311 B	1958	37	\N	1848	13.6	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5106.webp	f	\N	f
3453	J.I. Case 1031	Case IH	1031	1966	101.79	\N	4234	53.6	4x2	Diagonal 15.5x38	394	1634	\N	\N	29.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td511.webp	f	\N	f
3455	J.I. Case 1070	Case IH	1070	1970	101	\N	4676	49.8	4x2	Diagonal 18.4-34	467	1658	\N	\N	24.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td512.webp	f	\N	f
3457	J.I. Case 1090	Case IH	1090	2000	110	\N	4717	40.4	4x2	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td513.webp	f	\N	f
3459	J.I. Case 1170	Case IH	1170	1970	122	\N	6259	61.1	4x2	Diagonal 18.4-38	467	1760	\N	\N	29.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td514.webp	t	\N	f
1761	Kubota M7950DTM	Kubota	M7950DTM	1986	81	\N	3856	27.7	4x4	Diagonal 13.6-46	345	1756	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5141.webp	f	\N	f
1762	Kubota B7100HST	Kubota	B7100HST	1977	16	\N	573	4.8	4x4	Diagonal 8.3-16	211	765	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5147.webp	f	\N	f
3460	J.I. Case 1175	Case IH	1175	1971	122	\N	4626	61.1	4x2	Diagonal 18.4-38	467	1760	\N	\N	29.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td515.webp	t	\N	f
3461	J.I. Case 1190	Case IH	1190	1980	43	\N	2095	20.5	4x2	Diagonal 13.6x28	345	1298	\N	\N	11	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td516.webp	f	\N	f
3462	J.I. Case 1194	Case IH	1194	1983	49	\N	2109	20.5	4x2	Diagonal 12.4-32	315	1348	\N	\N	11	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td517.webp	f	\N	f
534	Massey Ferguson 9240	Massey Ferguson	9240	1995	226.31	\N	9013	83	4x4	Diagonal 95 - 19	2413	4585	\N	\N	47.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5087.webp	t	\N	f
1755	New Holland TG215	New Holland	TG215	2006	221	\N	9593	106.8	4x4	Diagonal 06 - 20	152	767	\N	\N	49.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5098.webp	t	\N	f
1756	Kubota L1500	Kubota	L1500	1971	14.8	\N	749	5.4	4x4	Diagonal 8-22	203	904	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5099.webp	f	\N	f
3458	Fiat 55-46	Fiat	55 46	1984	54.2	\N	2219	19.9	4x4	Diagonal 13-28	330	1273	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5138.webp	f	\N	f
538	John Deere 430C	John Deere	430C	1958	28.76	\N	1877	21.6	track	Diagonal 58 - 19	1473	2987	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5144.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1087/	f
1571	Ford FW-20	Steiger	fw 20	1977	210	\N	13433	120.8	4x4	Diagonal 24.5x32	622	1871	\N	\N	46.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td227.webp	f	\N	f
1572	Ford 1000	Shibaura	1000	1973	25	\N	1043	8.4	4x2	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td2277.webp	f	\N	f
1573	Ford TW-20	Ford	TW 20	1979	157.1	\N	5828	63	4x4	Diagonal 24.5-32	622	1871	\N	\N	33.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td228.webp	t	\N	f
1574	Ford FW-30	Steiger	fw 30	1977	265	\N	14202	123.7	4x4	Diagonal 24.5x32	622	1871	\N	\N	41.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td229.webp	f	\N	f
1576	Ford TW-30	Ford	TW 30	1979	188.2	\N	6622	73.6	4x4	Diagonal 24.5x32	622	1871	\N	\N	39.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td230.webp	t	\N	f
3463	J.I. Case 1200 Traction King	Case IH	1200 Traction King	1966	120	\N	7801	70.5	4x4	Diagonal 23.1-26	587	1658	\N	\N	31	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td518.webp	t	\N	f
3464	J.I. Case 1270	Case IH	1270	1972	127	\N	6078	56.4	4x2	Diagonal 18.4-38	467	1760	\N	\N	33.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td519.webp	t	\N	f
3465	J.I. Case 1290	Case IH	1290	1980	53	\N	2444	37.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	13.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td520.webp	f	\N	f
1763	Kubota L1-225	Kubota	L1 225	1986	21.7	\N	1088	8	4x4	Diagonal 9.5x24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5203.webp	f	\N	f
3466	J.I. Case 1294	Case IH	1294	1983	62	\N	3175	20.5	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td521.webp	f	\N	f
3467	J.I. Case 1370	Case IH	1370	1971	155.56	\N	5973	73.9	4x2	Diagonal 18.4-38	467	1760	\N	\N	36.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td522.webp	t	\N	f
3468	J.I. Case 1390	Case IH	1390	1980	60	\N	2494	38.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td523.webp	f	\N	f
3469	J.I. Case 1410	Case IH	1410	1976	81	\N	3220	29.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td524.webp	t	\N	f
3470	J.I. Case 1470 Traction King	Case IH	1470 Traction King	1969	145	\N	7847	78.9	4x4	Diagonal 18.4x30	467	1557	\N	\N	31	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td525.webp	t	\N	f
3471	J.I. Case 1490	Case IH	1490	1980	83	\N	5216	44.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	15.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td526.webp	t	\N	f
3472	J.I. Case 1570	Case IH	1570	1976	180	\N	6032	76.1	4x2	Diagonal 18.4-38	467	1760	\N	\N	45.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td527.webp	t	\N	f
3473	J.I. Case 1690	Case IH	1690	1980	90	\N	3971	46.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	22	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td528.webp	f	\N	f
3475	J.I. Case 2090	Case IH	2090	1979	108	\N	5456	49.9	4x2	Diagonal 18.4-34	467	1658	\N	\N	27.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td529.webp	f	\N	f
1767	Kubota BX1850	Kubota	BX1850	2006	18	\N	569	5	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5295.webp	f	\N	f
1768	Kubota BX2350	Kubota	BX2350	2006	23	\N	599	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5296.webp	f	\N	f
1769	Kubota B3300SU	Kubota	B3300SU	2000	33	\N	875	9.2	4x4	Diagonal 15-19.5	381	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5298.webp	f	\N	f
1770	Kubota L3700SU	Kubota	L3700SU	2010	37.4	\N	1164	11	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5299.webp	f	\N	f
3476	J.I. Case 2094	Case IH	2094	1979	127	\N	4966	53	4x4	Diagonal 23.1x34	587	1861	\N	\N	27.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td530.webp	f	\N	f
1771	Kubota BX2230	Kubota	BX2230	2004	22	\N	585	6.1	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5300.webp	f	\N	f
1772	Kubota BX1500	Kubota	BX1500	2003	15	\N	550	3.9	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5301.webp	f	\N	f
3478	J.I. Case 2390	Case IH	2390	1979	160.72	\N	6472	71.3	4x2	Diagonal 18.4-38	467	1760	\N	\N	40.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td532.webp	t	\N	f
3479	J.I. Case 2470 Traction King	Case IH	2470 Traction King	1972	213	\N	7030	80.3	4x4	Diagonal 18.4-30	467	1557	\N	\N	43.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td533.webp	t	\N	f
3480	J.I. Case 2590	Case IH	2590	1979	180	\N	6747	66.2	4x2	Diagonal 18.4-38	467	1760	\N	\N	43.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td534.webp	t	\N	f
3481	J.I. Case 2670 Traction King	Case IH	2670 Traction King	1974	256	\N	7425	80.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	54.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td535.webp	t	\N	f
3482	J.I. Case 2870 Traction King	Case IH	2870 Traction King	1976	300	\N	11385	117.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	61.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td536.webp	t	\N	f
3483	J.I. Case 3294	Case IH	3294	1984	197	\N	7711	72.2	4x4	Diagonal 23.1x34	587	1861	\N	\N	40.1	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td537.webp	t	\N	f
3484	J.I. Case 4490	Case IH	4490	1979	210	\N	9453	95.2	4x4	Diagonal 20.8-34	528	1762	\N	\N	43.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td538.webp	t	\N	f
3485	J.I. Case 4690	Case IH	4690	1979	261	\N	10119	109.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	54.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td539.webp	t	\N	f
3487	J.I. Case 4890	Case IH	4890	1979	300	\N	11680	122.9	4x4	Diagonal 20.8-34	528	1762	\N	\N	58.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td540.webp	t	\N	f
3494	Challenger MT225B	Iseki	mt225b	2005	22.5	\N	1399	6.5	4x4	Diagonal 33x12.50-16.5	318	838	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5514.webp	f	\N	f
1774	New Holland T7030	New Holland	T7030	2007	156	\N	7125	72.7	4x4	Diagonal 07 - 20	178	810	\N	\N	36	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5474.webp	t	\N	f
315	John Deere B	John Deere	B	1935	16	\N	1485	7.7	4x2	Diagonal 48x5.25	1219	2206	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td26.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1046/	f
561	John Deere 2305	John Deere	2305	2005	24.1	\N	657	6.6	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5468.webp	f	\N	f
1775	New Holland T7040	New Holland	T7040	2007	180	\N	7125	74.7	4x4	Diagonal 07 - 20	178	810	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5475.webp	t	\N	f
1776	New Holland T7050	New Holland	T7050	2007	195	\N	7125	73.7	4x4	Diagonal 07 - 20	178	810	\N	\N	41.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5476.webp	t	\N	f
70	John Deere 5625 (2007-2008)	John Deere	5625	2007	99	\N	2735	32.1	4x4	Radial 420/90R30	420	1518	\N	\N	20.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5473.webp	t	\N	f
1792	Ford 5110 Mark III	Ford	5110 Mark III	1988	65	\N	3840	23.8	4x2	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5493.webp	f	\N	f
1793	Ford 6410 Mark III	Ford	6410 Mark III	1988	80	\N	3810	29.4	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5494.webp	f	\N	f
1794	Ford 6810 Mark III	Ford	6810 Mark III	1988	90	\N	3592	30.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5495.webp	t	\N	f
1795	Ford 7910	Ford	7910	1985	98	\N	5225	36	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5496.webp	f	\N	f
563	John Deere 8010	John Deere	8010	1961	215	\N	8935	78.9	4x4	Diagonal 18.00x25	457	1412	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td55.webp	f	\N	f
1796	Massey Ferguson 3315	Massey Ferguson	3315	2001	55	\N	2150	20.2	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5503.webp	f	\N	f
1797	Massey Ferguson 3330	Massey Ferguson	3330	2001	67.1	\N	2349	24.6	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5504.webp	f	\N	f
1798	Massey Ferguson 3340	Massey Ferguson	3340	2001	79.1	\N	2349	29	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5505.webp	f	\N	f
3491	Challenger MT275	Iseki	mt275	2003	40.1	\N	1409	11.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5511.webp	t	\N	f
3492	Challenger MT285	Iseki	mt285	2003	40.1	\N	1439	11.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5512.webp	t	\N	f
3493	Challenger MT295	Iseki	mt295	2003	44.2	\N	1940	13.6	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5513.webp	f	\N	f
3495	Challenger MT255B	Iseki	mt255b	2005	28.4	\N	1075	8.9	4x4	Diagonal 36x13.50-15	343	914	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5515.webp	f	\N	f
3496	Challenger MT265B	Iseki	mt265b	2005	33	\N	3000	9.5	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5516.webp	f	\N	f
1777	New Holland T7060	New Holland	T7060	2007	210	\N	7125	69.5	4x4	Diagonal 07 - 20	178	810	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5477.webp	t	\N	f
3497	Challenger MT275B	Iseki	mt275b	2005	40.1	\N	3000	11.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5517.webp	t	\N	f
3498	Challenger MT285B	Iseki	mt285b	2005	47.5	\N	3800	13.9	4x4	Diagonal 44x18.00-20	457	1118	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5518.webp	f	\N	f
3499	Challenger MT295B	Iseki	mt295b	2005	52.1	\N	1690	15	4x4	Diagonal 44x18.00-20	457	1118	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5519.webp	f	\N	f
1780	New Holland T8020	New Holland	T8020	2007	244.1	\N	8959	89.4	4x4	Diagonal 07 - 20	178	810	\N	\N	55.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5480.webp	t	\N	f
1781	New Holland T8030	New Holland	T8030	2007	269.6	\N	9239	92.2	4x4	Diagonal 07 - 20	178	810	\N	\N	59.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5481.webp	t	\N	f
1782	New Holland T8040	New Holland	T8040	2007	304.4	\N	9239	93	4x4	Diagonal 07 - 20	178	810	\N	\N	62.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5482.webp	t	\N	f
1788	New Holland T6020 Elite	New Holland	T6020 Elite	2007	110	\N	4938	49.9	4x4	Diagonal 07 - 20	178	810	\N	\N	23.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5488.webp	t	\N	f
1789	New Holland T6030 Elite	New Holland	T6030 Elite	2007	115	\N	5368	53.3	4x4	Diagonal 07 - 20	178	810	\N	\N	24.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5489.webp	t	\N	f
1790	New Holland T6050 Elite	New Holland	T6050 Elite	2007	125	\N	5368	52.7	4x4	Diagonal 07 - 20	178	810	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5490.webp	t	\N	f
1791	New Holland T6070 Elite	New Holland	T6070 Elite	2007	140	\N	5368	52.8	4x4	Diagonal 07 - 20	178	810	\N	\N	30.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5491.webp	t	\N	f
1634	New Holland TC18	New Holland	TC18	1999	18.5	\N	652	5.5	4x4	Diagonal 9.5x16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3091.webp	f	\N	f
1635	New Holland TC21	New Holland	TC21	1999	21	\N	657	6.2	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3092.webp	f	\N	f
1637	New Holland TC25	New Holland	TC25	1999	25	\N	1122	8	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3094.webp	f	\N	f
1639	New Holland TC29	New Holland	TC29	1999	29	\N	1122	9.2	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3096.webp	f	\N	f
1640	New Holland TC30	New Holland	TC30	2001	30	\N	994	9.4	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3097.webp	f	\N	f
1641	New Holland TC33	New Holland	TC33	1999	33	\N	1122	10.5	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3098.webp	f	\N	f
1642	New Holland TC35	New Holland	TC35	2000	35	\N	1475	10.9	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3099.webp	f	\N	f
3500	Challenger MT297B	Iseki	mt297b	2005	59.1	\N	1849	17	4x4	Diagonal 18.4-24	467	1404	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5520.webp	f	\N	f
3503	Challenger MT575B	Challenger	mt575b	2007	185	\N	7302	68.5	4x4	Radial 18.4R42	467	1861	\N	\N	40.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5523.webp	t	\N	f
564	John Deere 445	John Deere	445	1963	36	\N	2095	13.2	4x2	Diagonal 12x28	305	1229	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5552.webp	f	\N	f
565	John Deere 1420	John Deere	1420	1970	43	\N	1065	15.8	4x2	Diagonal 13.6x24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5553.webp	f	\N	f
566	John Deere 2420	John Deere	2420	1970	66	\N	3172	24.2	4x2	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5554.webp	f	\N	f
567	John Deere 3420	John Deere	3420	1970	77	\N	3478	28.3	4x2	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5555.webp	f	\N	f
568	John Deere 4420	John Deere	4420	1970	102	\N	3757	37.4	4x2	Diagonal 23.1x30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5556.webp	f	\N	f
1801	Massey Ferguson 30	Massey Ferguson	30	1963	30	\N	1360	11	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5551.webp	f	\N	f
571	John Deere 3330	John Deere	3330	1977	78.6	\N	4731	27.8	4x2	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5560.webp	f	\N	f
572	John Deere 3530	John Deere	3530	1975	105	\N	5474	33.7	4x2	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5561.webp	f	\N	f
573	John Deere 4530	John Deere	4530	1975	114	\N	6114	39.1	4x2	Diagonal 23.1x30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5562.webp	f	\N	f
574	John Deere 4930	John Deere	4930	1978	160	\N	5226	47.7	4x4	Diagonal 24.5x32	622	1871	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5564.webp	t	\N	f
575	John Deere 4730	John Deere	4730	1977	117	\N	4944	40.4	4x2	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5565.webp	f	\N	f
1803	New Holland T1110	New Holland	holland t1110	2005	28	\N	676	7.5	4x4	Diagonal 29x12.5-15	318	737	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5580.webp	f	\N	f
1804	New Holland T1010	New Holland	holland t1010	2008	20	\N	659	5.7	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5581.webp	f	\N	f
1805	New Holland T1030	New Holland	holland t1030	2008	26	\N	659	7.2	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5582.webp	f	\N	f
1806	New Holland T2310	New Holland	T2310	2008	40	\N	1826	12.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5583.webp	f	\N	f
1807	New Holland T2320	New Holland	T2320	2008	45	\N	1866	14.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5584.webp	f	\N	f
1808	New Holland T2330	New Holland	T2330	2008	50	\N	1586	16.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5585.webp	f	\N	f
1809	New Holland T1510	New Holland	T1510	2008	30	\N	1081	9.4	4x2	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5586.webp	f	\N	f
1810	New Holland T1520	New Holland	T1520	2008	35	\N	1088	10.8	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5587.webp	f	\N	f
570	John Deere 2730	John Deere	2730	1975	74	\N	4399	27.1	4x2	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5559.webp	f	\N	f
1802	Massey Ferguson 168	Massey Ferguson	168	1972	69	\N	2207	21.6	4x4	Diagonal 12x36	305	1433	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5566.webp	f	\N	f
1662	New Holland 9484	Versatile	holland 9484	2000	310	\N	8547	113.7	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3122.webp	t	\N	f
1687	New Holland TB100	New Holland	TB100	2003	100	\N	3141	29.4	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3149.webp	t	\N	f
1663	New Holland 9684	Versatile	holland 9684	2000	360	\N	8949	139.5	4x4	Diagonal 20.8-42	528	1965	\N	\N	70	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3123.webp	t	\N	f
1664	New Holland TJ275	New Holland	TJ275	2002	275	\N	14417	100.6	4x4	Radial 18.4R46	467	1963	\N	\N	56.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3124.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1244/	f
1665	New Holland TJ325	New Holland	TJ325	2002	325	\N	14481	117.7	4x4	Radial 18.4R46	467	1963	\N	\N	65.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3125.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1245/	f
1666	New Holland TJ375	New Holland	TJ375	2002	375	\N	17059	149.7	4x4	Radial 18.4R46	467	1963	\N	\N	72.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3126.webp	t	\N	f
1826	CaseIH Steiger 385QT Quadtrac	CaseIH	Steiger 385QT Quadtrac	2008	385	\N	21840	124.4	track	Diagonal 08 - 20	203	853	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5605.webp	t	\N	f
1818	Ford 7710	Ford	7710	1982	97	\N	2987	39.2	4x4	Diagonal 18.4-30	467	1557	\N	\N	21.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5596.webp	t	\N	f
576	John Deere 1010	John Deere	1010	1960	36.13	\N	1519	16.1	4x2	Diagonal 10-34	254	1295	\N	\N	13.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td56.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1395/	f
1821	CaseIH Steiger 335	CaseIH	Steiger 335	2008	335	\N	13499	138.8	4x4	Radial 20.8R42	528	1965	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5600.webp	t	\N	f
1822	CaseIH Steiger 385	CaseIH	Steiger 385	2008	385	\N	17191	184	4x4	Radial 710/70R42	710	2061	\N	\N	65.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5601.webp	t	\N	f
1823	CaseIH Steiger 435	CaseIH	Steiger 435	2008	435	\N	17191	163.1	4x4	Radial 710/70R42	710	2061	\N	\N	92.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5602.webp	t	\N	f
1824	CaseIH Steiger 485	CaseIH	Steiger 485	2008	485	\N	17463	194.9	4x4	Radial 710/70R42	710	2061	\N	\N	100.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5603.webp	t	\N	f
1830	CaseIH STX440	CaseIH	STX440	2002	440	\N	17837	198.1	4x4	Radial 20.8R42	528	1965	\N	\N	86.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5609.webp	t	\N	f
1837	CaseIH STX330	CaseIH	STX330	2006	330	\N	14649	138.8	4x4	Radial 480/80R46	480	1936	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5616.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1370/	f
1842	CaseIH STX480	CaseIH	STX480	2006	480	\N	20250	198.5	4x4	Radial 520/85R42	520	1951	\N	\N	101.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5621.webp	t	\N	f
1819	CaseIH JX1085C	CaseIH	JX1085C	2005	80	\N	3134	26.4	4x4	Diagonal 05 - 20	127	724	\N	\N	18.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5597.webp	f	\N	f
1820	CaseIH JX1095C	CaseIH	JX1095C	2005	90	\N	3166	30.7	4x4	Diagonal 05 - 20	127	724	\N	\N	19.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5598.webp	t	\N	f
1825	CaseIH Steiger 535	CaseIH	Steiger 535	2008	535	\N	19341	173.5	4x4	Diagonal 4.5x12	114	499	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5604.webp	t	\N	f
1827	CaseIH Steiger 435QT Quadtrac	CaseIH	Steiger 435QT Quadtrac	2008	435	\N	21840	139	track	Diagonal 08 - 20	203	853	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5606.webp	t	\N	f
1828	CaseIH Steiger 485QT Quadtrac	CaseIH	Steiger 485QT Quadtrac	2008	485	\N	22226	157.4	track	Diagonal 08 - 20	203	853	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5607.webp	t	\N	f
1829	CaseIH Steiger 535QT Quadtrac	CaseIH	Steiger 535QT Quadtrac	2008	535	\N	23133	222.7	track	Diagonal 08 - 20	203	853	\N	\N	110.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5608.webp	t	\N	f
1832	CaseIH JX80U	CaseIH	JX80U	2002	74	\N	3778	24.7	4x4	Diagonal 02 - 20	51	594	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5611.webp	f	\N	f
1833	CaseIH JX90U	CaseIH	JX90U	2002	84	\N	3950	28.6	4x4	Diagonal 02 - 20	51	594	\N	\N	18.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5612.webp	t	\N	f
1834	CaseIH JX100U	CaseIH	JX100U	2002	92	\N	3950	30.6	4x4	Diagonal 02 - 20	51	594	\N	\N	18.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5613.webp	t	\N	f
1835	CaseIH JX1095N	CaseIH	JX1095N	2005	91	\N	2639	29.4	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5614.webp	t	\N	f
1838	CaseIH STX380	CaseIH	STX380	2006	380	\N	17191	184	4x4	Diagonal 06 - 20	152	767	\N	\N	85.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5617.webp	t	\N	f
1840	CaseIH STX430	CaseIH	STX430	2006	430	\N	17191	163.1	4x4	Diagonal 06 - 20	152	767	\N	\N	92.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5619.webp	t	\N	f
1857	Kubota M4900	Kubota	M4900	2001	54	\N	1799	16.5	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5702.webp	f	\N	f
339	John Deere 7610	John Deere	7610	1997	140	\N	6004	60.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3214.webp	t	\N	f
340	John Deere 3255	John Deere	3255	1991	100	\N	4636	75.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3216.webp	t	\N	f
341	John Deere 9400	John Deere	9400	1997	425	\N	15318	170.9	4x4	Radial 710/70R38	710	1959	\N	\N	65.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3221.webp	t	\N	f
342	John Deere 8100	John Deere	8100	1995	160	\N	8108	96	4x4	Radial 18.4R46	467	1963	\N	\N	36.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3222.webp	t	\N	f
343	John Deere 8200	John Deere	8200	1995	180	\N	8118	104.4	4x4	Radial 18.4R46	467	1963	\N	\N	41.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3224.webp	t	\N	f
344	John Deere 8210	John Deere	8210	1999	185	\N	8118	67.9	track	Radial 18.4R46	467	1963	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3225.webp	t	\N	f
1845	CaseIH Maxxum 110	CaseIH	maxxum 110	2007	110	\N	4340	40.9	4x4	Radial 18.4R38	467	1760	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5624.webp	t	\N	f
1846	CaseIH Maxxum 115	CaseIH	maxxum 115	2007	115	\N	4293	45.5	4x4	Radial 18.4R38	467	1760	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5625.webp	t	\N	f
1847	CaseIH Maxxum 120	CaseIH	maxxum 120	2007	129	\N	4819	55.7	4x4	Radial 18.4R38	467	1760	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5626.webp	t	\N	f
1848	CaseIH Maxxum 125	CaseIH	maxxum 125	2007	125	\N	4293	46.2	4x4	Radial 18.4R38	467	1760	\N	\N	26.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5627.webp	t	\N	f
1849	CaseIH Maxxum 130	CaseIH	maxxum 130	2007	130	\N	4819	54.6	4x4	Radial 18.4R38	467	1760	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5628.webp	t	\N	f
1850	CaseIH Maxxum 140	CaseIH	maxxum 140	2007	139	\N	4949	52.8	4x4	Radial 18.4R38	467	1760	\N	\N	30.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5629.webp	t	\N	f
1858	Kubota L4610	Kubota	L4610	1999	47.8	\N	1451	14.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5703.webp	f	\N	f
3504	J.I. Case 2294	Case IH	2294	1984	154	\N	5021	57.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	33.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5665.webp	t	\N	f
3505	J.I. Case 2394	Case IH	2394	1984	197	\N	6472	68.9	4x2	Diagonal 18.4x38	467	1760	\N	\N	39.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5666.webp	t	\N	f
3506	J.I. Case 2594	Case IH	2594	1984	217	\N	6747	75.1	4x2	Diagonal 20.8x38	528	1863	\N	\N	45.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5667.webp	t	\N	f
1859	Kubota MX4700	Kubota	MX4700	2009	48.2	\N	1640	14.5	4x2	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5706.webp	f	\N	f
1860	Ford 4110	Ford	4110	1982	56.8	\N	1968	25.3	4x2	Diagonal 16.9-24	429	1339	\N	\N	11.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5709.webp	f	\N	f
1861	CaseIH Farmall 31	Shibaura	farmall 31	2008	31	\N	1138	9.7	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5749.webp	f	\N	f
1862	CaseIH Farmall 35	Shibaura	farmall 35	2008	35	\N	1145	10.6	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5750.webp	f	\N	f
1863	CaseIH Farmall 40	Shibaura	farmall 40	2008	40	\N	1557	12.8	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5751.webp	f	\N	f
1864	CaseIH Farmall 45	Shibaura	farmall 45	2008	45	\N	1597	14.5	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5752.webp	f	\N	f
1865	CaseIH Farmall 50	Shibaura	farmall 50	2008	50	\N	1597	16.4	4x4	Diagonal 44x18-20	457	1118	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5753.webp	f	\N	f
1866	CaseIH Farmall 55	Shibaura	farmall 55	2004	55	\N	1909	17.6	4x4	Diagonal 14.9x28	378	1355	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5754.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1250/	f
1867	CaseIH Farmall 60	Shibaura	farmall 60	2007	60	\N	1909	18.9	4x4	Diagonal 14.9x28	378	1355	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5755.webp	t	\N	f
580	John Deere 6900	John Deere	6900	1994	130	\N	5391	47.7	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5765.webp	t	\N	f
1869	CaseIH Farmall DX34	Shibaura	dx34	2006	35	\N	1145	10.6	4x4	Diagonal 06 - 20	152	767	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5757.webp	f	\N	f
1870	CaseIH Farmall DX60	Shibaura	dx60	2007	60	\N	1909	18.9	4x4	Diagonal 07 - 20	178	810	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5758.webp	t	\N	f
1699	CaseIH MX215 Magnum	CaseIH	MX215 Magnum	2006	221	\N	9541	79.2	4x4	Diagonal 06 - 20	152	767	\N	\N	49.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3402.webp	t	\N	f
1146	Kubota M10570 (2000-2024)	Kubota	M10570	2000	103.6	\N	3709	38	4x2	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td11029.webp	f	\N	f
367	John Deere R	John Deere	R	1949	43	\N	3356	29.5	4x2	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td34.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1093/	f
368	Massey Ferguson 185	Massey Ferguson	185	1971	75	\N	2721	27.5	4x2	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3401.webp	f	\N	f
593	John Deere 2010	John Deere	2010	1960	46.86	\N	2131	20.3	4x2	Diagonal 14.9-28	378	1355	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td58.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1392/	f
581	John Deere 6800	John Deere	6800	1993	120	\N	4989	44	4x4	Radial 18.8R38	478	1777	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5767.webp	t	\N	f
582	John Deere 6600	John Deere	6600	1993	110	\N	4649	40.4	4x4	Radial 18.8R38	478	1777	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5768.webp	t	\N	f
583	John Deere 5045E	John Deere	5045E	2008	45	\N	2299	13.6	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5789.webp	t	\N	f
1872	New Holland 1215	Shibaura	holland 1215	1996	16	\N	616	5	4x4	Diagonal 8x16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td579.webp	f	\N	f
584	John Deere 5055D	John Deere	5055D	2008	55	\N	1900	18.8	4x2	Diagonal 14.9-28	378	1355	\N	\N	11.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5790.webp	t	\N	f
585	John Deere 5055E	John Deere	5055E	2008	55	\N	2299	18.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	11.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5791.webp	t	\N	f
586	John Deere 5065E	John Deere	5065E	2008	65	\N	2299	21.3	4x4	Diagonal 16.9-27	429	1416	\N	\N	13.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5792.webp	t	\N	f
1	John Deere 5075E	John Deere	5075E	2008	75	65000	2299	23.6	4x4	Diagonal 16.9-28	429	1441	\N	65000	15.1	5	inactive	2026-04-21 06:46:20.86626	/uploads/tractors/td5793.webp	t	\N	f
587	John Deere 5083E	John Deere	5083E	2008	83	\N	3265	25.4	4x4	Diagonal 18.4-30	467	1557	\N	\N	16.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5794.webp	t	\N	f
588	John Deere 5093E	John Deere	5093E	2008	93	\N	3349	29.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	18.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5795.webp	t	\N	f
590	John Deere 6100D	John Deere	6100D	2008	98.9	\N	3299	39.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5797.webp	t	\N	f
591	John Deere 6115D	John Deere	6115D	2008	118.4	\N	3701	43.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	23.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5798.webp	t	\N	f
592	John Deere 6130D	John Deere	6130D	2008	129.8	\N	3959	46.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	25.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5799.webp	t	\N	f
1873	New Holland 1220	Shibaura	holland 1220	1996	17	\N	648	5.3	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td580.webp	f	\N	f
594	John Deere 6140D	John Deere	6140D	2008	137.8	\N	3959	49.1	4x4	Diagonal 18.4-34	467	1658	\N	\N	26.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5800.webp	t	\N	f
595	John Deere 5065M	John Deere	5065M	2008	65	\N	2729	20.9	4x2	Diagonal 16.9-30	429	1492	\N	\N	12.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5801.webp	t	\N	f
596	John Deere 5075M	John Deere	5075M	2008	75	\N	2729	24.1	4x2	Diagonal 16.9-30	429	1492	\N	\N	14.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5802.webp	t	\N	f
597	John Deere 5085M	John Deere	5085M	2008	85	\N	2899	27.2	4x2	Diagonal 16.9-30	429	1492	\N	\N	17.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5803.webp	t	\N	f
126	John Deere 5095M (2008-2011)	John Deere	5095M	2008	95	\N	2989	31	4x4	Diagonal 14.9-28	378	1355	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5804.webp	t	\N	f
598	John Deere 5105M (2008-2011)	John Deere	5105M	2008	105	\N	3492	29.9	4x4	Diagonal 14.9-28	378	1355	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5805.webp	t	\N	f
1874	Ford 1310	Shibaura	1310	1983	19	\N	1025	6.1	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td581.webp	f	\N	f
1875	New Holland 1320	Shibaura	holland 1320	1996	20	\N	1011	6.2	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td582.webp	f	\N	f
1876	Ford 1510	Shibaura	1510	1983	22	\N	1040	8.7	4x4	Diagonal 13.6x16	345	994	\N	\N	5.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td583.webp	f	\N	f
1877	New Holland 1520	Shibaura	holland 1520	1996	23	\N	1033	7.2	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td584.webp	f	\N	f
1878	New Holland 1530	Shibaura	holland 1530	1997	25	\N	1122	8	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td585.webp	f	\N	f
600	John Deere 3005	John Deere	3005	2008	27.5	\N	954	8.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5852.webp	f	\N	f
601	John Deere 4105	John Deere	4105	2008	41	\N	1354	11.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5853.webp	t	\N	f
589	John Deere 5101E	John Deere	5101E	2008	101	\N	3320	30.7	4x4	Diagonal 18.4-30	467	1557	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5796.webp	t	\N	f
1710	CaseIH CS 68	CaseIH	CS 68	1994	68	\N	3099	23.6	4x4	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3601.webp	t	\N	f
1711	CaseIH CS 75	CaseIH	CS 75	1994	75	\N	3099	25.6	4x4	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3602.webp	t	\N	f
1714	CaseIH CS 78	CaseIH	CS 78	1994	78	\N	3949	26	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3609.webp	t	\N	f
1715	CaseIH CS 86	CaseIH	CS 86	1995	86	\N	3949	28.9	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3613.webp	t	\N	f
1716	CaseIH CS 94	CaseIH	CS 94	1994	94	\N	3949	31.5	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3614.webp	t	\N	f
1717	CaseIH CVX 120	CaseIH	CVX 120	2000	120	\N	6271	44	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3630.webp	f	\N	f
1718	CaseIH CVX 130	CaseIH	CVX 130	2000	130	\N	6271	47.7	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3631.webp	f	\N	f
1719	CaseIH CVX 150	CaseIH	CVX 150	2000	150	\N	6371	55	4x4	Radial 580/70R42	580	1879	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3632.webp	f	\N	f
1720	CaseIH CVX 170	CaseIH	CVX 170	2000	170	\N	6651	62.4	4x4	Radial 580/70R42	580	1879	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3633.webp	f	\N	f
1721	New Holland 3010	New Holland	3010	1996	55	\N	2587	15.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3678.webp	f	\N	f
1722	New Holland 5010	New Holland	5010	2000	70	\N	2397	25.7	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3680.webp	f	\N	f
383	John Deere 4400	John Deere	4400	1998	35.7	\N	1315	10.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3687.webp	f	\N	f
602	John Deere 4005	John Deere	4005	2008	41.9	\N	1440	12.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5854.webp	f	\N	f
1879	Kubota BX2660	Kubota	BX2660	2008	25.5	\N	630	7.2	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5855.webp	f	\N	f
1880	Kubota M95X	Kubota	M95X	2005	95	\N	4105	29.4	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5856.webp	t	\N	f
1881	Kubota M105X	Kubota	M105X	2005	105	\N	4076	33	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5857.webp	t	\N	f
1882	Kubota M108S	Kubota	M108S	2007	108	\N	3150	37.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	23.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5858.webp	t	\N	f
1883	New Holland 1620	Shibaura	holland 1620	1996	27.3	\N	1066	8.1	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td586.webp	f	\N	f
1885	Kubota B2620	Kubota	B2620	2008	26	\N	704	7	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5861.webp	f	\N	f
1886	Kubota B2920	Kubota	B2920	2008	29	\N	704	7.7	4x4	Diagonal 11.2-16	284	890	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5862.webp	f	\N	f
1887	Kubota MX5100	Kubota	MX5100	2009	52.2	\N	1642	16.1	4x2	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5863.webp	t	\N	f
1888	Kubota M96S	Kubota	M96S	2007	95	\N	3370	30.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5864.webp	t	\N	f
1729	New Holland 9282	Versatile	holland 9282	1996	260	\N	7766	111.3	4x4	Radial 20.8R38	528	1863	\N	\N	55.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3845.webp	t	\N	f
1730	New Holland 9482	Versatile	holland 9482	1996	310	\N	8547	149	4x4	Radial 20.8R42	528	1965	\N	\N	56.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3846.webp	t	\N	f
1731	New Holland 9682	Versatile	holland 9682	1996	360	\N	8949	154	4x4	Radial 20.8R42	528	1965	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3847.webp	t	\N	f
1732	New Holland 9882	Versatile	holland 9882	1996	425	\N	9176	194.7	4x4	Radial 710/70R38	710	1959	\N	\N	81.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td3848.webp	t	\N	f
391	Massey Ferguson 5455	Massey Ferguson	5455	2005	95	\N	4220	38.8	4x4	Radial 18.4R38	467	1760	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3855.webp	t	\N	f
393	Massey Ferguson 5470	Massey Ferguson	5470	2005	125	\N	4710	42.3	4x4	Radial 18.4R38	467	1760	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3858.webp	t	\N	f
394	Massey Ferguson 1523	Iseki	ferguson 1523	2005	22.5	\N	694	6.9	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3859.webp	f	\N	f
395	Massey Ferguson 1528	Iseki	ferguson 1528	2005	28.4	\N	1099	9	4x4	Diagonal 9.5x24	241	1020	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3860.webp	f	\N	f
396	Massey Ferguson 1531	Iseki	ferguson 1531	2005	33	\N	1099	9	4x4	Diagonal 9.5x24	241	1020	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3861.webp	f	\N	f
397	Massey Ferguson 1533	Iseki	ferguson 1533	2005	33	\N	1372	9.5	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3862.webp	f	\N	f
398	Massey Ferguson 1540	Iseki	ferguson 1540	2005	40.1	\N	1387	10.8	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3863.webp	t	\N	f
402	Massey Ferguson 1417	Iseki	ferguson 1417	2003	16.6	\N	645	4.9	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3867.webp	f	\N	f
403	Massey Ferguson 1423	Iseki	ferguson 1423	2002	23.3	\N	679	7.2	4x4	Diagonal 12-16.5	305	937	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3868.webp	f	\N	f
392	Massey Ferguson 5460	Massey Ferguson	5460	2005	105	\N	4524	37.3	4x4	Diagonal 05 - 20	127	724	\N	\N	21.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3856.webp	t	\N	f
1892	Massey Ferguson 2645	Massey Ferguson	2645	1985	110	\N	5248	40.4	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5872.webp	f	\N	f
1893	Massey Ferguson 2685	Massey Ferguson	2685	1985	130	\N	5320	47.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5873.webp	t	\N	f
1895	Massey Ferguson 8690	Massey Ferguson	8690	2011	340	\N	10092	112	4x4	Radial 480/80R50	480	2038	\N	\N	66.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5875.webp	t	\N	f
1896	Massey Ferguson 2605	TAFE	ferguson 2605	2007	38	\N	2054	11.7	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5876.webp	f	\N	f
1897	Massey Ferguson 2615	TAFE	ferguson 2615	2007	49	\N	2186	15.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5877.webp	f	\N	f
400	Massey Ferguson 1552	Iseki	ferguson 1552	2005	52	\N	1661	15	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3865.webp	f	\N	f
401	Massey Ferguson 1560	Iseki	ferguson 1560	2005	59.1	\N	1849	17	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3866.webp	f	\N	f
405	Massey Ferguson 1429	Iseki	ferguson 1429	2002	28.4	\N	1240	8.4	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3870.webp	f	\N	f
604	John Deere 2010C	John Deere	2010C	1960	47.45	\N	3804	44.9	track	Diagonal 60 - 19	1524	3073	\N	\N	15.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td59.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1398/	f
407	Massey Ferguson 1433	Iseki	ferguson 1433	2002	33	\N	1274	9.9	4x4	Diagonal 15-19.5	381	1143	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3872.webp	f	\N	f
408	Massey Ferguson 1440	Iseki	ferguson 1440	2002	40.1	\N	1361	11.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3873.webp	t	\N	f
605	John Deere 5215	Carraro	deere 5215	2003	56	\N	2950	20.5	4x2	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5905.webp	t	\N	f
414	Massey Ferguson 8460	Massey Ferguson	8460	2004	235	\N	8680	88.4	4x4	Radial 18.4R46	467	1963	\N	\N	47.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3903.webp	t	\N	f
415	Massey Ferguson 8470	Massey Ferguson	8470	2004	260	\N	9049	91.5	4x4	Radial 18.4R46	467	1963	\N	\N	53.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3904.webp	t	\N	f
416	Massey Ferguson 8480	Massey Ferguson	8480	2004	290	\N	9049	98.2	4x4	Radial 18.4R46	467	1963	\N	\N	58.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3905.webp	t	\N	f
1898	Massey Ferguson 2625	TAFE	ferguson 2625	2007	63	\N	2580	19.8	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5878.webp	f	\N	f
1900	New Holland 1715	New Holland	1715	1996	27.3	\N	959	8.4	4x4	Diagonal 9.5x24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td588.webp	f	\N	f
1903	New Holland 1720	Shibaura	holland 1720	1996	27.7	\N	1220	8.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td589.webp	f	\N	f
1889	Kubota L3200 (2009-2011)	Kubota	L3200	2009	33	\N	1210	10.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5890.webp	f	\N	f
1904	Kubota L4100	Kubota	L4100	2009	41	\N	1464	12.7	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5891.webp	f	\N	f
603	John Deere 4075R	John Deere	4075R	2000	74.3	\N	1500	22	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5898.webp	t	\N	f
1905	New Holland 1725	Shibaura	holland 1725	1997	29	\N	1045	9.2	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td590.webp	f	\N	f
609	John Deere 5615	John Deere	5615	2001	90.5	\N	2790	25.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5909.webp	t	\N	f
610	John Deere 5715	John Deere	5715	2001	89	\N	2790	28.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5910.webp	t	\N	f
611	John Deere 3032E	John Deere	3032E	2008	31	\N	986	9.2	4x4	Diagonal 41x14.0-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5911.webp	t	\N	f
612	John Deere 3038E	John Deere	3038E	2008	37.1	\N	986	11	4x4	Diagonal 41x14.0-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5912.webp	f	\N	f
406	Massey Ferguson 1431	Iseki	ferguson 1431	2004	33	\N	1068	9.5	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3871.webp	f	\N	f
409	Massey Ferguson 1445	Iseki	ferguson 1445	2003	44.2	\N	1752	13.6	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3874.webp	f	\N	f
1899	Massey Ferguson Super 90	Massey Ferguson	Super 90	1961	77	\N	2442	41.5	4x2	Diagonal 15-30	381	1410	\N	\N	16.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5879.webp	f	\N	f
1901	Kubota X-20	Kubota	X 20	1987	19.7	\N	805	7.2	4x4	Diagonal 6-14	152	615	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5888.webp	f	\N	f
1902	Kubota X-24	Kubota	X 24	1987	23.7	\N	825	8.7	4x4	Diagonal 6-14	152	615	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5889.webp	f	\N	f
606	John Deere 5315	Agritalia	deere 5315	2003	66.5	\N	2950	24.4	4x2	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5906.webp	t	\N	f
607	John Deere 5415	Agritalia	deere 5415	2003	74	\N	5100	27.1	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5907.webp	f	\N	f
608	John Deere 5515	Agritalia	deere 5515	2003	82	\N	3050	30.1	4x2	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5908.webp	t	\N	f
1906	New Holland 1920	Shibaura	holland 1920	1996	33.3	\N	1392	10.5	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td592.webp	f	\N	f
1907	Ford 1120	Shibaura	1120	1987	14.7	\N	648	4.6	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5923.webp	f	\N	f
613	John Deere 8225R	John Deere	8225R	2009	225	\N	9863	87.2	4x4	Diagonal 1-3	25	119	\N	\N	43.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5914.webp	t	\N	f
616	John Deere 8295RT	John Deere	8295RT	2009	295	\N	15631	145.9	track	Diagonal 1-3	25	119	\N	\N	56.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5920.webp	t	\N	f
617	John Deere 8345RT (2009-2010)	John Deere	8345RT	2009	345	\N	15585	152.2	track	Diagonal 1-3	25	119	\N	\N	65.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5922.webp	t	\N	f
441	Massey Ferguson 593	Massey Ferguson	593	2006	89	\N	3299	31.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3933.webp	t	\N	f
440	Massey Ferguson 583	Massey Ferguson	583	2006	80	\N	2859	27	4x4	Diagonal 16.9-30	429	1492	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3932.webp	f	\N	f
442	Massey Ferguson 596	Massey Ferguson	596	2006	99	\N	3299	33.6	4x4	Diagonal 18.4-30	467	1557	\N	\N	20.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td3934.webp	t	\N	f
1908	Ford 1215	Shibaura	1215	1993	16	\N	616	5	4x4	Diagonal 8x16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5924.webp	f	\N	f
1909	Ford 1220	Shibaura	1220	1987	17	\N	648	5.3	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5925.webp	f	\N	f
1910	Ford 1320	Shibaura	1320	1987	20	\N	1011	6.2	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5926.webp	f	\N	f
1911	Ford 1520	Shibaura	1520	1987	23	\N	1033	7.2	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5927.webp	f	\N	f
1912	Ford 1620	Shibaura	1620	1992	27.3	\N	1066	8.1	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5928.webp	f	\N	f
1913	Ford 1715	Shibaura	1715	1992	27.3	\N	959	8.4	4x4	Diagonal 9.5x24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5929.webp	f	\N	f
1918	Ford 2120	Shibaura	2120	1987	42.6	\N	1749	12.7	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5933.webp	f	\N	f
1919	Ford 2810	Ford	2810	1983	36.5	\N	2265	17.9	4x4	Diagonal 13.6-28	345	1298	\N	\N	8.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5934.webp	f	\N	f
1920	Ford 2910	Ford	2910	1983	44	\N	2244	18.8	4x4	Diagonal 16.9-24	429	1339	\N	\N	8.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5935.webp	f	\N	f
1921	Ford 3230	Ford	3230	1990	37	\N	2437	19	4x4	Diagonal 12.4-28	315	1247	\N	\N	7.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5936.webp	f	\N	f
1922	Ford 3415	Shibaura	3415	1993	44	\N	1859	13.9	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5937.webp	f	\N	f
1923	Ford 3430	Ford	3430	1990	46	\N	2490	20.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	9.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5938.webp	f	\N	f
1924	Ford 3910	Ford	3910	1983	50	\N	2305	21.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	10.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5939.webp	f	\N	f
1925	Ford 2110	Shibaura	2110	1983	38	\N	1789	17.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	9.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td594.webp	f	\N	f
1926	Ford 3930	Ford	3930	1990	45	\N	2732	21.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5940.webp	t	\N	f
1927	Ford 4030	Fiat	4030	1992	51	\N	2299	18.7	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5941.webp	f	\N	f
1928	Ford 4130	Ford	4130	1990	63	\N	2100	20.2	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5942.webp	f	\N	f
1929	Ford 4230	Fiat	4230	1992	62	\N	2399	22.7	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5943.webp	f	\N	f
1930	Ford 4610	Ford	4610	1981	63	\N	3742	28.5	4x4	Diagonal 14.9-30	378	1405	\N	\N	12.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5944.webp	f	\N	f
1933	Ford 5610	Ford	5610	1982	72	\N	2583	33	4x4	Diagonal 18.4-30	467	1557	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5947.webp	f	\N	f
1934	Ford 5640	Ford	5640	1991	78.7	\N	3670	38.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5948.webp	f	\N	f
14	Ford 6610	Ford	6610	1982	82	\N	3311	35.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td5949.webp	f	\N	f
1935	New Holland 2120	Shibaura	holland 2120	1996	42.6	\N	1749	12.7	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td595.webp	f	\N	f
1936	Ford 6610S	Ford	6610S	1994	85	\N	2873	27.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5950.webp	f	\N	f
1937	Ford 6640	Ford	6640	1991	90.7	\N	3670	46.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5951.webp	f	\N	f
1938	Ford 7530	Ford	7530	1992	91	\N	3662	33.4	4x2	Diagonal 13.6x46	345	1756	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5952.webp	f	\N	f
1939	Ford 7610	Ford	7610	1982	97	\N	2692	39.2	4x4	Diagonal 18.4-30	467	1557	\N	\N	21.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5953.webp	t	\N	f
1940	Ford 7610S	Ford	7610S	1994	95	\N	2982	31.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5954.webp	t	\N	f
1941	Kubota B3200	Kubota	B3200	2008	32	\N	800	8.4	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5955.webp	f	\N	f
1942	Ford 7740	Ford	7740	1991	100.3	\N	3695	50.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	19.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5956.webp	t	\N	f
1943	Ford 7810	Ford	7810	1988	105	\N	4291	31.6	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5957.webp	f	\N	f
1944	Ford 7810S	Ford	7810S	1994	100	\N	3792	33	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5958.webp	f	\N	f
1945	Ford 7840	Ford	7840	1991	90	\N	4143	33.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5959.webp	f	\N	f
1946	Ford 8210	Ford	8210	1982	115	\N	4250	34.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5961.webp	f	\N	f
1947	Ford 8240	Ford	8240	1992	96	\N	4418	37	4x4	Diagonal 18.4-34	467	1658	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5962.webp	f	\N	f
465	Massey Ferguson 233	Massey Ferguson	233	1983	38	\N	2224	13.9	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4129.webp	f	\N	f
1948	Ford 8340	Ford	8340	1992	106	\N	4418	40.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5963.webp	t	\N	f
1949	Ford 8530	Ford	8530	1990	105	\N	5440	54.5	4x4	Diagonal 15-38	381	1613	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5964.webp	f	\N	f
1955	Ford 5610 Mark III	Ford	5610 Mark III	1988	72	\N	3592	23.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td597.webp	f	\N	f
1957	CaseIH Puma 225	CaseIH	Puma 225	2009	225	\N	7484	71.5	4x4	Radial 20.8R42	528	1965	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5972.webp	t	\N	f
3508	J.I. Case 4994	Case IH	4994	1984	400	\N	12020	153.5	4x4	Diagonal 20.8-38	528	1863	\N	\N	76.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5977.webp	t	\N	f
1959	CaseIH Steiger 330	CaseIH	Steiger 330	2007	330	\N	14649	138.8	4x4	Radial 480/80R46	480	1936	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5982.webp	t	\N	f
1954	CaseIH Magnum 180	CaseIH	Magnum 180	2009	180	\N	8618	74.7	4x4	Diagonal 09 - 20	229	897	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5969.webp	t	\N	f
1962	CaseIH Steiger 480	CaseIH	Steiger 480	2007	480	\N	20250	198.5	4x4	Radial 520/85R42	520	1951	\N	\N	101.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5985.webp	t	\N	f
1969	CaseIH MXU115	CaseIH	MXU115	2005	116	\N	5370	55	4x4	Radial 18.4R38	467	1760	\N	\N	24.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5992.webp	t	\N	f
625	John Deere 3010	John Deere	3010	1961	55.09	\N	2639	28.1	4x2	Diagonal 16.9-24	429	1339	\N	\N	15.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td60.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1388/	f
1970	New Holland 3415	Shibaura	holland 3415	1996	44	\N	1859	13.9	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td600.webp	f	\N	f
1971	New Holland 3430	New Holland	3430	1990	46	\N	2490	20.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	9.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td601.webp	f	\N	f
1972	New Holland 3830	New Holland	3830	1992	55	\N	1830	16.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td602.webp	f	\N	f
3512	J.I. Case S	Case IH	S	1941	21	\N	1984	7.7	4x2	Diagonal 11-26	279	1135	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td603.webp	f	\N	f
1974	Massey Ferguson 177	Massey Ferguson	177	2000	66	\N	2790	24.2	4x2	Diagonal 12-36	305	1433	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6039.webp	f	\N	f
1975	Massey Ferguson 178	Massey Ferguson	178	1968	73	\N	3119	22.7	4x4	Diagonal 15x30	381	1410	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6040.webp	f	\N	f
1977	New Holland 3930	New Holland	3930	1990	45	\N	2732	21.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td605.webp	t	\N	f
1956	CaseIH Magnum 190	CaseIH	Magnum 190	2009	190	\N	8618	69.5	4x4	Diagonal 09 - 20	229	897	\N	\N	41.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5970.webp	t	\N	f
3509	J.I. Case 4894	Case IH	4894	1983	300	\N	11680	122.9	4x4	Diagonal 18.4-34	467	1658	\N	\N	58.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5978.webp	t	\N	f
3510	J.I. Case 4694	Case IH	4694	1984	261	\N	10119	109.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	54.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5979.webp	t	\N	f
3511	J.I. Case 4494	Case IH	4494	1984	213	\N	9453	95.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	43.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5980.webp	t	\N	f
1961	CaseIH Steiger 430	CaseIH	Steiger 430	2007	430	\N	17191	163.1	4x4	Diagonal 07 - 20	178	810	\N	\N	92.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5984.webp	t	\N	f
1964	CaseIH STX530QT Quadtrac	CaseIH	STX530QT Quadtrac	2006	535	\N	23133	222.7	track	Diagonal 06 - 20	152	767	\N	\N	110.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5987.webp	t	\N	f
1965	CaseIH Magnum 215	CaseIH	Magnum 215	2008	221	\N	9117	79.2	4x4	Diagonal 08 - 20	203	853	\N	\N	49.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5988.webp	t	\N	f
1966	CaseIH Magnum 245	CaseIH	Magnum 245	2008	248	\N	9117	89.5	4x4	Diagonal 08 - 20	203	853	\N	\N	55.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5989.webp	t	\N	f
1967	CaseIH Magnum 275	CaseIH	Magnum 275	2007	275	\N	9357	135.3	4x4	Diagonal 07 - 20	178	810	\N	\N	57.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5990.webp	t	\N	f
618	John Deere 8100T	John Deere	8100T	1997	160	\N	10727	65.6	track	Diagonal 97 - 19	2464	4671	\N	\N	37.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5993.webp	t	\N	f
619	John Deere 8200T	John Deere	8200T	1997	180	\N	10727	109.4	track	Diagonal 97 - 19	2464	4671	\N	\N	41.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5994.webp	t	\N	f
620	John Deere 8300T	John Deere	8300T	1997	200	\N	10727	123.7	track	Diagonal 97 - 19	2464	4671	\N	\N	46.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5995.webp	t	\N	f
621	John Deere 8400T	John Deere	8400T	1997	225	\N	11340	124.5	track	Diagonal 97 - 19	2464	4671	\N	\N	51.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5996.webp	t	\N	f
1973	Ford 3055	Ford	3055	1970	55	\N	1999	20.2	4x4	Diagonal 11x36	279	1389	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6038.webp	f	\N	f
485	John Deere 620	John Deere	620	1956	48	\N	2657	26.3	4x2	Diagonal 12.4-38	315	1501	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td43.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1099/	f
486	John Deere 720	John Deere	720	1956	59	\N	3079	29.8	4x2	Diagonal 12-38	305	1483	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td44.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1082/	f
487	John Deere 320	John Deere	320	1956	21.5	\N	1247	7.9	4x2	Diagonal 9x24	229	998	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td45.webp	f	\N	f
489	John Deere 420	John Deere	420	1956	28.31	\N	1474	16.9	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td46.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1086/	f
1745	New Holland 9480	Versatile	holland 9480	1994	300	\N	10961	96.9	4x4	Diagonal 20.8x38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4602.webp	t	\N	f
1746	New Holland 9680	Versatile	holland 9680	1994	350	\N	11429	113	4x4	Diagonal 20.8x38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4603.webp	t	\N	f
1747	New Holland 9880	Versatile	holland 9880	1994	400	\N	11656	146.8	4x4	Diagonal 20.8x38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4604.webp	t	\N	f
1748	Ford 8401	Ford	8401	1980	109.25	\N	4750	34.5	4x2	Diagonal 23.1x30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4608.webp	f	\N	f
490	John Deere 2650	John Deere	2650	1987	78	\N	3800	28.6	4x4	Radial 13.6R38	345	1552	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4609.webp	t	\N	f
491	John Deere 2450	John Deere	2450	1987	70	\N	3509	25.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4610.webp	f	\N	f
492	John Deere 2250	John Deere	2250	1987	62	\N	3509	22.7	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4611.webp	f	\N	f
1749	Kubota L2600	Kubota	L2600	2000	27	\N	1070	8.3	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td4618.webp	f	\N	f
493	John Deere 3550	John Deere	3550	1988	125	\N	6509	45.9	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4687.webp	t	\N	f
517	John Deere 1850	John Deere	1850	1986	55	\N	3171	18.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4996.webp	f	\N	f
518	John Deere 1950	John Deere	1950	1988	61.7	\N	2945	22.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4997.webp	t	\N	f
520	John Deere 3350	John Deere	3350	1986	100	\N	4935	33.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4999.webp	f	\N	f
521	John Deere 530	John Deere	530	1958	37.52	\N	2249	20.7	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td50.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1080/	f
535	John Deere 630	John Deere	630	1958	48	\N	2657	26.3	4x2	Diagonal 12.4-38	315	1501	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td51.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1099/	f
628	John Deere 5010	John Deere	5010	1963	121	\N	5565	63	4x2	Diagonal 24.5-32	622	1871	\N	\N	30.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td62.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1397/	f
1990	New Holland 5640	New Holland	5640	1996	78.7	\N	3670	38.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td620.webp	f	\N	f
1991	Ford 6530	Ford	6530	1992	70	\N	3356	25.7	4x4	Diagonal 13.6x38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td621.webp	f	\N	f
1992	Ford 6610 Mark III	Ford	6610 Mark III	1988	86	\N	3592	26.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td622.webp	f	\N	f
1993	New Holland 6610S	New Holland	6610S	1994	85	\N	2873	27.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td623.webp	f	\N	f
1995	New Holland 6640	New Holland	6640	1996	90.7	\N	3670	46.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td625.webp	f	\N	f
1996	Massey Ferguson 8650	Massey Ferguson	ferguson 8650	2009	240	\N	10999	117.9	4x4	Radial 480/80R46	480	1936	\N	\N	45.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6263.webp	t	\N	f
1997	Massey Ferguson 8660	Massey Ferguson	ferguson 8660	2009	265	\N	10999	120.6	4x4	Radial 480/80R46	480	1936	\N	\N	50	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6264.webp	t	\N	f
1998	Massey Ferguson 8670	Massey Ferguson	ferguson 8670	2009	290	\N	10999	119.9	4x4	Radial 480/80R50	480	2038	\N	\N	54.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6265.webp	t	\N	f
1999	Massey Ferguson 8680	Massey Ferguson	ferguson 8680	2009	320	\N	10999	118.7	4x4	Radial 480/80R50	480	2038	\N	\N	59	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6266.webp	t	\N	f
3517	Challenger MT645C	Challenger	mt645c	2009	240	\N	10999	117.9	4x4	Radial 520/85R46	520	2052	\N	\N	45.8	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6267.webp	t	\N	f
3518	Challenger MT655C	Challenger	mt655c	2009	265	\N	10999	120.6	4x4	Radial 520/85R46	520	2052	\N	\N	50	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6268.webp	t	\N	f
3519	Challenger MT665C	Challenger	mt665c	2009	290	\N	10999	151.8	4x4	Radial 520/85R46	520	2052	\N	\N	54.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6269.webp	t	\N	f
3520	Challenger MT675C	Challenger	mt675c	2009	320	\N	10999	161.6	4x4	Radial 520/85R46	520	2052	\N	\N	59	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6270.webp	t	\N	f
3521	Challenger MT685C	Challenger	mt685c	2009	340	\N	10999	117.4	4x4	Radial 520/85R46	520	2052	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6271.webp	t	\N	f
3529	Challenger MT945C	Challenger	mt945c	2009	440	\N	17811	221.3	4x4	Radial 800/70R38	800	2085	\N	\N	90.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6279.webp	t	\N	f
3530	Challenger MT955C	Challenger	mt955c	2009	475	\N	17811	227.6	4x4	Radial 800/70R38	800	2085	\N	\N	98.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6280.webp	t	\N	f
516	John Deere 1750	John Deere	1750	1987	50	\N	2721	18.3	4x2	Diagonal 11-32	279	1288	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4995.webp	f	\N	f
519	John Deere 3050	John Deere	3050	1986	90.7	\N	4859	30.9	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td4998.webp	f	\N	f
1989	New Holland 5635	New Holland	5635	1996	75	\N	3200	24.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td619.webp	f	\N	f
1994	New Holland 6635	New Holland	6635	1996	85	\N	3400	27.9	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td624.webp	t	\N	f
1758	Massey Ferguson 365	Massey Ferguson	365	1988	61	\N	3485	20.2	4x4	Diagonal 15-30	381	1410	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5133.webp	f	\N	f
3456	Fiat 70-56	Fiat	70 56	1989	70	\N	2694	25.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5122.webp	f	\N	f
1757	Massey Ferguson 355	Massey Ferguson	355	1986	52	\N	2824	16.9	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5132.webp	t	\N	f
1759	Massey Ferguson 1200	Massey Ferguson	1200	1972	105	\N	5157	33.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5136.webp	f	\N	f
1760	Massey Ferguson 1250	Massey Ferguson	1250	1979	112	\N	6200	35.2	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5137.webp	f	\N	f
540	John Deere 7130	John Deere	7130	2007	125	\N	4380	36.7	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5231.webp	t	\N	f
541	John Deere 7230	John Deere	7230	2007	135	\N	4650	40.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5232.webp	t	\N	f
542	John Deere 7330	John Deere	7330	2007	150	\N	4898	45.9	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5233.webp	t	\N	f
543	John Deere 7430 Premium	John Deere	7430 Premium	2007	166	\N	6619	81.5	4x4	Radial 18.4R42	467	1861	\N	\N	35.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5234.webp	t	\N	f
1764	Ford 9030	Versatile	9030	1990	116	\N	4604	37.4	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5262.webp	t	\N	f
3474	Belarus 1052	Belarus	1052	2000	105	\N	3270	34.9	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5285.webp	t	\N	f
1765	Massey Ferguson 350	Massey Ferguson	350	1987	46	\N	2859	15	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5286.webp	f	\N	f
1766	Kubota BX1830	Kubota	BX1830	2004	18	\N	569	5	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5294.webp	f	\N	f
3531	Challenger MT965C	Challenger	mt965c	2009	525	\N	18038	232.7	4x4	Radial 800/70R38	800	2085	\N	\N	107.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6281.webp	t	\N	f
3532	Challenger MT975C	Challenger	mt975c	2009	585	\N	18038	205	4x4	Radial 800/70R38	800	2085	\N	\N	124.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6282.webp	t	\N	f
2000	Massey Ferguson GC2400	Iseki	ferguson gc2400	2008	22.5	\N	650	6.9	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6283.webp	f	\N	f
2001	Massey Ferguson GC2600	Iseki	ferguson gc2600	2008	25	\N	650	7.2	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6284.webp	f	\N	f
2002	New Holland 7610S	New Holland	7610S	1994	95	\N	2982	31.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td629.webp	t	\N	f
544	John Deere 9230	John Deere	9230	2007	325	\N	15214	153.2	4x4	Diagonal 07 - 20	178	810	\N	\N	66.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5235.webp	t	\N	f
545	John Deere 9330	John Deere	9330	2007	375	\N	15853	164.1	4x4	Diagonal 07 - 20	178	810	\N	\N	84.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5236.webp	t	\N	f
546	John Deere 9430	John Deere	9430	2007	425	\N	16492	196.3	4x4	Diagonal 07 - 20	178	810	\N	\N	84	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5237.webp	t	\N	f
547	John Deere 9530	John Deere	9530	2007	475	\N	17122	224.7	4x4	Diagonal 07 - 20	178	810	\N	\N	93.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5238.webp	t	\N	f
548	John Deere 9630	John Deere	9630	2007	530	\N	17122	238.7	4x4	Diagonal 07 - 20	178	810	\N	\N	105.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5239.webp	t	\N	f
549	John Deere 9430T	John Deere	9430T	2007	439	\N	20051	201.9	track	Diagonal 07 - 20	178	810	\N	\N	82.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5240.webp	t	\N	f
550	John Deere 9530T	John Deere	9530T	2007	491	\N	19874	225	track	Diagonal 07 - 20	178	810	\N	\N	92.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5241.webp	t	\N	f
551	John Deere 9630T	John Deere	9630T	2007	543	\N	19922	240.2	track	Diagonal 07 - 20	178	810	\N	\N	101.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5242.webp	t	\N	f
2004	New Holland 7635	New Holland	7635	1996	95	\N	3400	31.6	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td630.webp	t	\N	f
2003	Kubota M100X	Kubota	M100X	2009	100	\N	4020	32	4x4	Radial 18.4R30	467	1557	\N	\N	20.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6299.webp	t	\N	f
629	John Deere 3020	John Deere	3020	1964	70	\N	3238	33.5	4x2	Diagonal 13.6-38	345	1552	\N	\N	19.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td63.webp	f	\N	f
2005	Kubota M110X	Kubota	M110X	2009	110	\N	4105	34.9	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6300.webp	t	\N	f
558	John Deere 85F	Goldoni	deere 85f	2008	83	\N	2500	26.8	4x4	Diagonal 70x20	1778	3531	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5462.webp	t	\N	f
559	John Deere 100F	Goldoni	deere 100f	2008	96	\N	2520	30.5	4x4	Diagonal 70x20	1778	3531	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5463.webp	t	\N	f
553	John Deere 435	John Deere	435	1959	32.91	\N	1451	18.9	4x2	Diagonal 10-34	254	1295	\N	\N	8.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td54.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1381/	f
554	John Deere 3030	John Deere	3030	1978	93.8	\N	3309	28	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5401.webp	f	\N	f
560	John Deere 2320	John Deere	2320	2006	24.1	\N	752	6.6	4x4	Diagonal 31x12	787	1643	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5467.webp	f	\N	f
2013	CaseIH Farmall 80	Turk Tractor	farmall 80	2008	72	\N	2586	21.3	4x4	Diagonal 08 - 20	203	853	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6310.webp	t	\N	f
2014	CaseIH Farmall 90	Turk Tractor	farmall 90	2008	84	\N	2586	32.3	4x4	Diagonal 08 - 20	203	853	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6311.webp	t	\N	f
2015	CaseIH Farmall 95	Turk Tractor	farmall 95	2008	90	\N	2770	33	4x4	Diagonal 08 - 20	203	853	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6312.webp	t	\N	f
2016	CaseIH Farmall 65C	CaseIH	Farmall 65C	2008	64	\N	2619	31.1	4x4	Diagonal 08 - 20	203	853	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6313.webp	t	\N	f
2017	CaseIH Farmall 75C	CaseIH	Farmall 75C	2008	76	\N	2619	31.1	4x4	Diagonal 08 - 20	203	853	\N	\N	16.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6314.webp	t	\N	f
2020	CaseIH Farmall 85U	CaseIH	Farmall 85U	2008	85	\N	2899	27.4	4x2	Diagonal 08 - 20	203	853	\N	\N	17	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6317.webp	t	\N	f
2006	Kubota M126X	Kubota	M126X	2009	126	\N	4599	39.6	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6301.webp	t	\N	f
2007	Kubota M128X	Kubota	M128X	2008	134	\N	4409	41.5	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6302.webp	f	\N	f
2008	Kubota M135X	Kubota	M135X	2009	135	\N	4599	62.7	4x4	Radial 18.4R38	467	1760	\N	\N	28.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6303.webp	t	\N	f
2018	CaseIH Farmall 85C	CaseIH	Farmall 85C	2008	84	\N	2949	32.4	4x4	Diagonal 13.6x28	345	1298	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6315.webp	t	\N	f
2019	CaseIH Farmall 95C	CaseIH	Farmall 95C	2008	95	\N	3000	32.3	4x4	Radial 16.9R24	429	1339	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6316.webp	t	\N	f
2023	New Holland 7740	New Holland	7740	1996	100.3	\N	3695	50.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	19.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td632.webp	t	\N	f
552	John Deere 4610	John Deere	4610	2002	42.8	\N	1564	12.3	4x4	Diagonal 44x18.00	1118	2357	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5386.webp	f	\N	f
3486	Fiat 605C	Fiat	605C	1970	56	\N	2760	20.5	track	Diagonal 70 - 19	1778	3505	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5393.webp	f	\N	f
555	John Deere 3140	John Deere	3140	1980	97	\N	4404	30.8	4x4	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td542.webp	f	\N	f
1773	New Holland TG245	New Holland	TG245	2006	248	\N	9648	117.4	4x4	Diagonal 06 - 20	152	767	\N	\N	55.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5444.webp	t	\N	f
556	John Deere 20A	Goldoni	deere 20a	2008	21	\N	750	6.2	4x4	Diagonal 80x15	2032	3835	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5460.webp	f	\N	f
557	John Deere 76F	Goldoni	deere 76f	2008	76	\N	1900	24.2	4x4	Diagonal 70x24	1778	3632	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5461.webp	t	\N	f
2021	CaseIH Farmall 95U	CaseIH	Farmall 95U	2008	95	\N	3099	27.9	4x2	Diagonal 08 - 20	203	853	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6318.webp	t	\N	f
2022	CaseIH Farmall 105U	CaseIH	Farmall 105U	2008	105	\N	3099	34.6	4x2	Diagonal 08 - 20	203	853	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6319.webp	t	\N	f
2024	New Holland T7070	New Holland	T7070	2009	225	\N	7248	86.6	4x4	Diagonal 09 - 20	229	897	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6322.webp	t	\N	f
2025	New Holland T8050	New Holland	T8050	2007	320.5	\N	9239	109.3	4x4	Diagonal 07 - 20	178	810	\N	\N	68.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6323.webp	t	\N	f
2026	New Holland T8010	New Holland	T8010	2007	221	\N	8959	106.8	4x4	Diagonal 07 - 20	178	810	\N	\N	49.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6324.webp	t	\N	f
2030	New Holland TJ330	New Holland	TJ330	2006	330	\N	14569	138.8	4x4	Radial 20.8R42	528	1965	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6328.webp	t	\N	f
2031	New Holland TJ380	New Holland	TJ380	2006	380	\N	18872	184	4x4	Radial 20.8R42	528	1965	\N	\N	85.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6329.webp	t	\N	f
2027	New Holland TG275	New Holland	TG275	2006	275	\N	9239	132.5	4x4	Diagonal 06 - 20	152	767	\N	\N	54.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6325.webp	t	\N	f
2028	New Holland TG305	New Holland	TG305	2006	304	\N	9239	150	4x4	Diagonal 06 - 20	152	767	\N	\N	61.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6326.webp	t	\N	f
1799	Massey Ferguson 3350	Massey Ferguson	3350	2001	90	\N	2349	33	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5506.webp	t	\N	f
1800	Massey Ferguson 3355	Massey Ferguson	3355	2001	93.7	\N	2349	34.4	4x4	Radial 320/70R24	320	1058	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5507.webp	t	\N	f
3488	Challenger MT225	Iseki	mt225	2003	23.3	\N	758	7	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5508.webp	f	\N	f
3489	Challenger MT255	Iseki	mt255	2003	28.4	\N	1019	8.8	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5509.webp	f	\N	f
3490	Challenger MT265	Iseki	mt265	2003	33	\N	1379	9.9	4x4	Diagonal 12.6-24	320	1154	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td5510.webp	f	\N	f
2032	New Holland TJ430	New Holland	TJ430	2006	430	\N	18872	163.1	4x4	Radial 20.8R42	528	1965	\N	\N	92.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6330.webp	t	\N	f
2033	New Holland TJ480	New Holland	TJ480	2006	480	\N	20171	198.5	4x4	Radial 20.8R42	528	1965	\N	\N	101.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6331.webp	t	\N	f
2034	New Holland TJ530	New Holland	TJ530	2006	530	\N	24494	194.4	4x4	Radial 20.8R42	528	1965	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6332.webp	t	\N	f
2035	New Holland T9020	New Holland	T9020	2007	335	\N	14569	138.8	4x4	Radial 710/70R42	710	2061	\N	\N	68.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6333.webp	t	\N	f
2036	New Holland T9030	New Holland	T9030	2007	385	\N	18872	184	4x4	Radial 710/70R42	710	2061	\N	\N	85.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6334.webp	t	\N	f
2037	New Holland T9040	New Holland	T9040	2007	435	\N	18872	163.1	4x4	Radial 710/70R42	710	2061	\N	\N	92.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6335.webp	t	\N	f
2038	New Holland T9050	New Holland	T9050	2007	485	\N	19813	194.9	4x4	Radial 710/70R42	710	2061	\N	\N	100.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6336.webp	t	\N	f
2039	New Holland T9060	New Holland	T9060	2007	535	\N	24494	173.5	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6337.webp	t	\N	f
2040	New Holland Boomer 8N	New Holland	Boomer 8N	2009	50	\N	1705	14.7	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6338.webp	f	\N	f
2042	New Holland 7810S	New Holland	7810S	1994	100	\N	3792	33	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td634.webp	f	\N	f
2041	New Holland T5040	New Holland	T5040	2008	85	\N	4499	26.6	4x4	Diagonal 08 - 20	203	853	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6339.webp	t	\N	f
2046	New Holland T4020	New Holland	holland t4020	2008	64	\N	2499	27.9	4x4	Radial 16.9R30	429	1492	\N	\N	13.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6343.webp	t	\N	f
2047	New Holland T4030	New Holland	T4030	2008	76	\N	2499	27.9	4x4	Radial 16.9R30	429	1492	\N	\N	16.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6344.webp	t	\N	f
2048	New Holland T4040	New Holland	T4040	2008	84	\N	2499	28.4	4x4	Radial 16.9R30	429	1492	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6345.webp	t	\N	f
2049	New Holland T4050	New Holland	T4050	2008	95	\N	2499	28.3	4x4	Radial 16.9R30	429	1492	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6346.webp	t	\N	f
2052	New Holland 7840	New Holland	7840	1996	90	\N	4143	33.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td635.webp	f	\N	f
2060	New Holland TD80D	Turk Traktor	holland td80d	2007	72	\N	2586	22.7	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6357.webp	f	\N	f
2043	New Holland T5050	New Holland	T5050	2008	95	\N	4499	27.9	4x4	Diagonal 08 - 20	203	853	\N	\N	18.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6340.webp	t	\N	f
2044	New Holland T5060	New Holland	T5060	2008	105	\N	4499	28.8	4x4	Diagonal 08 - 20	203	853	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6341.webp	t	\N	f
2045	New Holland T5070	New Holland	T5070	2008	115	\N	4499	28.3	4x4	Diagonal 08 - 20	203	853	\N	\N	22.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6342.webp	t	\N	f
2050	New Holland TK4030	New Holland	TK4030	2009	76.4	\N	3279	23.5	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6347.webp	t	\N	f
2051	New Holland TK4050	New Holland	TK4050	2009	93.9	\N	4169	30.5	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6348.webp	t	\N	f
2053	New Holland TK4060	New Holland	TK4060	2009	99.2	\N	4900	31.6	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6350.webp	t	\N	f
2088	New Holland TN85A	New Holland	TN85A	2004	80	\N	2775	30.1	4x4	Diagonal 04 - 20	102	681	\N	\N	18.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6465.webp	f	\N	f
2089	New Holland TN95A	New Holland	TN95A	2004	90	\N	2775	28.3	4x4	Diagonal 04 - 20	102	681	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6467.webp	t	\N	f
1813	New Holland T2410	Shibaura	holland t2410	2008	55	\N	1932	17.6	4x4	Diagonal 14.9-28	378	1355	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5590.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1250/	f
1814	New Holland T2420	Shibaura	holland t2420	2008	60	\N	1932	18.9	4x4	Diagonal 14.9-28	378	1355	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5591.webp	t	\N	f
1817	Massey Ferguson 271XE	Massey Ferguson	271XE	2001	59	\N	2540	21.6	4x2	Diagonal 16.9x30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5594.webp	f	\N	f
1811	New Holland TC31DA	New Holland	TC31DA	2005	31	\N	1122	9.1	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5588.webp	f	\N	f
2066	Massey Ferguson 1635	Massey Ferguson	1635	2009	35.7	\N	1440	9.9	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6363.webp	f	\N	f
2067	Massey Ferguson 1643	Massey Ferguson	1643	2009	43.5	\N	1534	12.6	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6364.webp	f	\N	f
2068	Massey Ferguson 1648	Massey Ferguson	1648	2009	47.1	\N	1685	13.9	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6365.webp	f	\N	f
2069	Massey Ferguson 1652	Massey Ferguson	1652	2009	52.2	\N	1714	15	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6366.webp	f	\N	f
2070	Massey Ferguson 1655	Massey Ferguson	1655	2009	55.4	\N	1710	15.8	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6367.webp	f	\N	f
2071	Massey Ferguson 1660	Massey Ferguson	1660	2009	60	\N	1850	17	4x4	Diagonal 16.9x26	429	1390	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6368.webp	f	\N	f
2072	Massey Ferguson 2620	Massey Ferguson	2620	1981	102	\N	5311	37.4	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6377.webp	f	\N	f
2073	Massey Ferguson 2680	Massey Ferguson	2680	1981	130	\N	5719	47.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6378.webp	t	\N	f
2074	Massey Ferguson 2720	Massey Ferguson	2720	1982	147	\N	6129	53.9	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6379.webp	t	\N	f
2075	New Holland 8160	New Holland	8160	1996	90	\N	5269	33	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td638.webp	f	\N	f
631	John Deere 2720	John Deere	2720	2008	31.4	\N	894	8.6	4x4	Diagonal 14-17.5	356	1049	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6384.webp	f	\N	f
632	John Deere 4020	John Deere	4020	1963	95.83	\N	3826	45.3	4x2	Diagonal 15.5-38	394	1634	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td64.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1401/	f
2077	New Holland 8260	New Holland	8260	1996	100	\N	5269	39.3	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td641.webp	f	\N	f
2078	New Holland 8340	New Holland	8340	1996	106	\N	4418	40.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td642.webp	t	\N	f
2080	New Holland 8360	New Holland	8360	1996	115	\N	5368	43.7	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td643.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1113/	f
2081	CaseIH Farmall 45A	CaseIH	Farmall 45A	2010	45	\N	1740	14.3	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6432.webp	f	\N	f
2082	CaseIH Farmall 55A (2010-2015)	CaseIH	Farmall 55A	2010	55	\N	1849	18.1	4x4	Diagonal 14.9x28	378	1355	\N	\N	13.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6433.webp	t	\N	f
2083	CaseIH Farmall 65A (2010-2015)	CaseIH	Farmall 65A	2010	65	\N	2580	22.6	4x4	Diagonal 16.9x30	429	1492	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6434.webp	f	\N	f
15	CaseIH Farmall 75A (2010-2015)	CaseIH	Farmall 75A	2010	75	\N	2580	25	4x4	Diagonal 16.9x30	429	1492	\N	\N	16.3	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td6435.webp	f	\N	f
3533	J.I. Case 990	Case IH	990	1976	58	\N	3039	32.6	4x4	Diagonal 12.4-36	315	1450	\N	\N	13.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6439.webp	f	\N	f
2091	New Holland Boomer 1020	New Holland	holland boomer 1020	2008	20	\N	659	5.7	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6472.webp	f	\N	f
1812	New Holland TC34DA	New Holland	TC34DA	2005	35	\N	1140	10.6	4x4	Diagonal 05 - 20	127	724	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5589.webp	f	\N	f
2086	New Holland TN70A	New Holland	TN70A	2004	70	\N	2456	26.9	4x4	Diagonal 04 - 20	102	681	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6459.webp	t	\N	f
2087	New Holland TN75A	New Holland	TN75A	2004	75	\N	2456	27.3	4x4	Diagonal 04 - 20	102	681	\N	\N	15.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6462.webp	t	\N	f
2090	New Holland 8670	New Holland	8670	1993	170	\N	7166	77.3	4x4	Diagonal 93 - 20	2362	4524	\N	\N	34.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td647.webp	t	\N	f
2103	Massey Ferguson 3645	Agritalia	ferguson 3645	2007	91	\N	2500	27.5	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6484.webp	t	\N	f
1854	CaseIH Puma 140	CaseIH	Puma 140	2008	144	\N	6725	57.4	4x4	Radial 18.4R38	467	1760	\N	\N	28.8	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/3bea8ec8eef94c8ea003cc59e932323d?v=7776a91c	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA_SWB.pdf#page=9	t
1855	CaseIH Puma 155	CaseIH	Puma 155	2008	157	\N	6725	62.8	4x4	Radial 18.4R38	467	1760	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/e308bbb26b7c4d9289354ee961a433da?v=5cd844b4	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA_SWB.pdf#page=9	t
2094	New Holland Boomer 2030	New Holland	Boomer 2030	2008	31	\N	1181	9.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6475.webp	f	\N	f
1853	CaseIH Puma 125	CaseIH	Puma 125	2008	125	\N	6001	53.7	4x4	Radial 18.4R38	467	1760	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5632.webp	t	\N	f
2104	New Holland 8770	New Holland	8770	1993	190	\N	7529	0.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td649.webp	t	\N	f
1852	CaseIH Puma 115	CaseIH	Puma 115	2008	115	\N	6001	54.1	4x4	Diagonal 08 - 20	203	853	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5631.webp	t	\N	f
2095	New Holland Boomer 2035	New Holland	Boomer 2035	2008	35	\N	1188	10.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6476.webp	f	\N	f
1856	New Holland TC40A	New Holland	TC40A	2003	40	\N	1297	12.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5681.webp	f	\N	f
2096	New Holland Boomer 3040	New Holland	Boomer 3040	2008	40	\N	1576	12.8	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6477.webp	f	\N	f
579	John Deere 7405	John Deere	7405	1998	105	\N	5250	38.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5701.webp	t	\N	f
2092	New Holland Boomer 1025	New Holland	holland boomer 1025	2008	26	\N	659	7.2	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6473.webp	f	\N	f
2093	New Holland Boomer 1030	New Holland	holland boomer 1030	2000	28	\N	676	8	4x4	Diagonal 29x12.5-15	318	737	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6474.webp	f	\N	f
2098	New Holland Boomer 3050	New Holland	Boomer 3050	2008	50	\N	1586	15.8	4x4	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6479.webp	f	\N	f
2101	Massey Ferguson 3625	Agritalia	ferguson 3625	2007	68	\N	2500	20.2	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6482.webp	t	\N	f
2102	Massey Ferguson 3635	Agritalia	ferguson 3635	2007	78	\N	2500	23.8	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6483.webp	t	\N	f
633	John Deere 1020	John Deere	1020	1965	38.82	\N	1909	18.9	4x2	Diagonal 12.4-28	315	1247	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td65.webp	f	\N	f
2097	New Holland Boomer 3045	New Holland	Boomer 3045	2008	45	\N	1617	14.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6478.webp	f	\N	f
578	John Deere 1010C	John Deere	1010C	1960	35	\N	3438	33.3	track	Diagonal 60 - 19	1524	3073	\N	\N	9.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td57.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1391/	f
2110	Ford Commander 6000	Ford	Commander 6000	1965	65	\N	3234	33.1	4x2	Diagonal 13.6-38	345	1552	\N	\N	23.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6586.webp	f	\N	f
2099	New Holland Boomer 4055	New Holland	Boomer 4055	2008	55	\N	1918	17.6	4x4	Diagonal 14.9-24	378	1253	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6480.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1250/	f
2100	New Holland Boomer 4060	New Holland	Boomer 4060	2008	60	\N	1918	18.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6481.webp	t	\N	f
2105	Massey Ferguson 7497	Massey Ferguson	7497	2009	205	\N	7426	77.2	4x4	Diagonal 09 - 20	229	897	\N	\N	43.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6499.webp	f	\N	f
2106	Ford 8830 (1990-1993)	Ford	8830	1990	170	\N	6441	62.8	4x4	Diagonal 15-38	381	1613	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td650.webp	t	\N	f
2107	Massey Ferguson 7499	Massey Ferguson	7499	2009	220	\N	7426	78.2	4x4	Diagonal 09 - 20	229	897	\N	\N	47.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6500.webp	t	\N	f
2108	Ford 8870	Ford	8870	1993	210	\N	8232	82.5	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td651.webp	t	\N	f
2109	Ford 8970	Ford	8970	1993	240	\N	7688	124.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	43.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td652.webp	t	\N	f
634	John Deere 5620	John Deere	5620	2003	72	\N	3549	22.4	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6596.webp	f	\N	f
635	John Deere 5720	John Deere	5720	2003	80	\N	3700	25.3	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6597.webp	t	\N	f
639	John Deere 5070M	John Deere	5070M	2009	70	\N	6001	25.7	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6602.webp	t	\N	f
640	John Deere 5080M	John Deere	5080M	2009	80	\N	6001	29.4	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6603.webp	t	\N	f
636	John Deere 5820	John Deere	5820	2003	88	\N	3700	27.9	4x4	Diagonal 03 - 20	76	638	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6598.webp	t	\N	f
637	John Deere 5080R	John Deere	5080R	2009	80	\N	3700	24.6	4x4	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6599.webp	t	\N	f
3534	J.I. Case 1896	Case IH	1896	1984	95	\N	6121	55	4x4	Diagonal 18.4-38	467	1760	\N	\N	21.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6634.webp	t	\N	f
3535	J.I. Case 2096	Case IH	2096	1984	116	\N	5386	57.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6635.webp	t	\N	f
2124	New Holland 9884	Versatile	holland 9884	2000	425	\N	9176	155.9	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6663.webp	t	\N	f
2125	Massey Ferguson 595	Massey Ferguson	595	1974	86.8	\N	4100	31.8	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6664.webp	t	\N	f
2129	CaseIH D25	CaseIH	D25	2001	25	\N	1122	8	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6668.webp	f	\N	f
2130	CaseIH D29	CaseIH	D29	2001	29	\N	1122	9.2	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6669.webp	f	\N	f
2131	CaseIH D33	CaseIH	D33	2001	33	\N	1122	10.5	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6670.webp	f	\N	f
2134	CaseIH DX25	CaseIH	DX25	2001	25	\N	1122	7.4	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6673.webp	f	\N	f
3536	Zetor 14245	Zetor	14245	1990	140	\N	5062	45.9	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6675.webp	t	\N	f
3537	Zetor 11245	Zetor	11245	1990	105	\N	4819	34.9	4x4	Diagonal 16.9x38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6676.webp	f	\N	f
3538	Zetor 7520	Zetor	7520	1995	71	\N	3329	23.1	4x2	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6677.webp	f	\N	f
3539	Zetor 7540	Zetor	7540	1995	71	\N	3671	23.1	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6678.webp	f	\N	f
3540	Zetor 5320	Zetor	5320	1995	60	\N	3059	22	4x2	Diagonal 16.9x30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6679.webp	f	\N	f
3541	Zetor 5340	Zetor	5340	1995	60	\N	3729	22	4x4	Diagonal 16.9x28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6680.webp	f	\N	f
2136	Massey Ferguson 2650 HD	Massey Ferguson	2650 HD	2010	74	\N	2887	24.6	4x2	Diagonal 16.9-30	429	1492	\N	\N	15.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6682.webp	t	\N	f
2137	Massey Ferguson 2660 HD	Massey Ferguson	ferguson 2660 hd	2010	81	\N	3515	26	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6683.webp	t	\N	f
2138	Massey Ferguson 2670 HD	Massey Ferguson	ferguson 2670 hd	2010	91	\N	3830	30.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	18.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6684.webp	t	\N	f
2139	Massey Ferguson 2680 HD	Massey Ferguson	ferguson 2680 hd	2010	97	\N	3857	32.3	4x4	Diagonal 18.4-30	467	1557	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6685.webp	t	\N	f
2143	Massey Ferguson 6497	Massey Ferguson	6497	2008	200	\N	7801	87.6	4x4	Radial 18.4R42	467	1861	\N	\N	42.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6704.webp	t	\N	f
24	John Deere 5090R (2009-2025)	John Deere	5090R	2009	90	\N	3700	28.6	4x4	Diagonal 23.1-26	587	1658	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6600.webp	t	\N	f
25	John Deere 5100R (2009-2025)	John Deere	5100R	2009	100	\N	3700	31.9	4x4	Diagonal 23.1-26	587	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6601.webp	t	\N	f
643	John Deere 5080G	Agritalia	deere 5080g	2009	80	\N	3050	29.4	4x4	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6606.webp	t	\N	f
644	John Deere 5090G	Agritalia	deere 5090g	2009	90	\N	3050	33	4x2	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6609.webp	t	\N	f
645	John Deere 5100GF	Agritalia	deere 5100gf	2009	100	\N	2619	36.7	4x2	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6613.webp	t	\N	f
2121	New Holland T6060 Elite	New Holland	T6060 Elite	2007	130	\N	4938	54.6	4x4	Diagonal 07 - 20	178	810	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6658.webp	t	\N	f
2122	New Holland T6080 Elite	New Holland	T6080 Elite	2007	155	\N	5600	62.8	4x4	Diagonal 07 - 20	178	810	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6659.webp	t	\N	f
2123	New Holland TV6070	New Holland	TV6070	2008	155	\N	6896	52.6	4x4	Diagonal 08 - 20	203	853	\N	\N	30.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6660.webp	t	\N	f
2135	Massey Ferguson 2635	TAFE	ferguson 2635	2010	74	\N	2429	22.7	4x4	Diagonal 10 - 20	254	940	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6681.webp	t	\N	f
1890	New Holland 1630	Shibaura	holland 1630	1997	27.3	\N	1122	8.8	4x2	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td587.webp	f	\N	f
2164	CaseIH Puma 185	CaseIH	Puma 185	2011	182	\N	6725	68.8	4x4	Diagonal 11 - 20	279	983	\N	\N	36.3	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/4bed3f5c2fc14cc7aceedcc85b4694a6?v=707335bb	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA_SWB.pdf#page=9	t
2144	Massey Ferguson 6499	Massey Ferguson	6499	2008	215	\N	7801	105.4	4x4	Radial 18.4R42	467	1861	\N	\N	46.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6705.webp	t	\N	f
2150	CaseIH Steiger 350	CaseIH	Steiger 350	2011	350	\N	16260	125.2	4x4	Diagonal 1-3	25	119	\N	\N	66.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6726.webp	t	\N	f
648	John Deere 8260R	John Deere	8260R	2011	260	\N	12346	103.3	4x4	Diagonal 1-3	25	119	\N	\N	52.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6713.webp	t	\N	f
649	John Deere 8285R	John Deere	8285R	2011	285	\N	12346	100.8	4x4	Diagonal 1-3	25	119	\N	\N	58.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6714.webp	t	\N	f
650	John Deere 8310R	John Deere	8310R	2011	310	\N	12346	110.6	4x4	Diagonal 1-3	25	119	\N	\N	60.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6715.webp	t	\N	f
651	John Deere 8335R	John Deere	8335R	2011	335	\N	12346	116.9	4x4	Diagonal 1-3	25	119	\N	\N	67.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6716.webp	t	\N	f
652	John Deere 8360R	John Deere	8360R	2011	360	\N	12346	121.9	4x4	Diagonal 1-3	25	119	\N	\N	72.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6717.webp	t	\N	f
2168	New Holland Boomer 30	New Holland	Boomer 30	2011	28	\N	1321	8.8	4x4	Diagonal 41x14.00-20	356	1041	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6744.webp	f	\N	f
2151	CaseIH Steiger 400	CaseIH	Steiger 400	2011	400	\N	16351	177.2	4x4	Diagonal 1-3	25	119	\N	\N	82.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6727.webp	t	\N	f
653	John Deere 8310RT	John Deere	8310RT	2011	310	\N	17690	156	track	Diagonal 12-20	305	1026	\N	\N	60.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6718.webp	t	\N	f
654	John Deere 8335RT	John Deere	8335RT	2011	335	\N	17690	154.8	track	Diagonal 12-20	305	1026	\N	\N	65.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6719.webp	t	\N	f
655	John Deere 8360RT	John Deere	8360RT	2011	360	\N	17690	157.1	track	Diagonal 12-20	305	1026	\N	\N	70.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6720.webp	t	\N	f
2152	CaseIH Steiger 450	CaseIH	Steiger 450	2011	450	\N	16351	174.1	4x4	Diagonal 1-3	25	119	\N	\N	90.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6728.webp	t	\N	f
2154	CaseIH Steiger 550	CaseIH	Steiger 550	2011	550	\N	19979	231.1	4x4	Diagonal 1-3	25	119	\N	\N	106	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6730.webp	t	\N	f
2155	CaseIH Steiger 600	CaseIH	Steiger 600	2011	600	\N	20805	215	4x4	Diagonal 1-3	25	119	\N	\N	104.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6731.webp	t	\N	f
2156	CaseIH Steiger 450 Quadtrac	CaseIH	Steiger 450 Quadtrac	2014	450	\N	24625	213.6	track	Diagonal 1-3	25	119	\N	\N	91.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6732.webp	t	\N	f
2157	CaseIH Steiger 500 Quadtrac	CaseIH	Steiger 500 Quadtrac	2011	500	\N	24625	223.1	track	Diagonal 1-3	25	119	\N	\N	102.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6733.webp	t	\N	f
2158	CaseIH Steiger 550 Quadtrac	CaseIH	Steiger 550 Quadtrac	2014	550	\N	24405	233.3	track	Diagonal 1-3	25	119	\N	\N	105.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6734.webp	t	\N	f
2159	CaseIH Steiger 600 Quadtrac	CaseIH	Steiger 600 Quadtrac	2014	600	\N	24405	251	track	Diagonal 1-3	25	119	\N	\N	105.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6735.webp	t	\N	f
1914	New Holland 1925	Shibaura	holland 1925	1997	34	\N	1089	10.7	4x4	Diagonal 13.6-16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td593.webp	f	\N	f
1915	Ford 1720	Shibaura	1720	1987	27.7	\N	1220	8.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5930.webp	f	\N	f
1916	Ford 1910	Shibaura	1910	1983	32	\N	1472	14.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	8.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5931.webp	f	\N	f
1917	Ford 1920	Shibaura	1920	1987	33.3	\N	1392	10.5	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5932.webp	f	\N	f
2169	New Holland Boomer 35	New Holland	Boomer 35	2011	38	\N	1321	11.8	4x4	Diagonal 41x14.00-20	356	1041	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6745.webp	f	\N	f
2170	New Holland Boomer 40	New Holland	Boomer 40	2011	41	\N	1609	12.6	4x4	Diagonal 41x14.00-20	356	1041	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6746.webp	f	\N	f
2171	New Holland Boomer 50	New Holland	Boomer 50	2011	47	\N	1609	14.5	4x4	Diagonal 41x14.00-20	356	1041	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6747.webp	f	\N	f
2184	Kubota L3800	Kubota	L3800	2011	37.4	\N	1205	11.6	4x2	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6784.webp	f	\N	f
2185	Kubota BX1860	Kubota	BX1860	2009	18	\N	569	5	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6785.webp	f	\N	f
2186	Kubota BX2360	Kubota	BX2360	2009	23	\N	599	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6786.webp	f	\N	f
562	John Deere 5603 (2000-2024)	John Deere	5603	2000	75	\N	2390	23.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	21.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td5472.webp	f	\N	f
660	John Deere 1023E	John Deere	1023E	2011	23.5	\N	610	5.6	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6788.webp	f	\N	f
59	John Deere 1026R (2011-2013)	John Deere	1026R	2011	25.2	\N	654	6.6	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6789.webp	f	\N	f
661	John Deere 6520L	John Deere	6520L	2002	95	\N	3800	34.9	4x2	Diagonal 18.4-26	467	1455	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6797.webp	t	\N	f
2188	Kubota M5640SU	Kubota	M5640SU	2000	56	\N	1699	18.3	4x2	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6799.webp	t	\N	f
662	John Deere 5020	John Deere	5020	1965	140	\N	6581	72	4x2	Diagonal 18.4-38	467	1760	\N	\N	31	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td68.webp	f	\N	f
2189	Kubota M5140	Kubota	M5140	2010	52	\N	2063	16.9	4x2	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6801.webp	t	\N	f
2177	New Holland T9.390	New Holland	T9.390	2011	354	\N	19051	125.2	4x4	Diagonal 1-3	25	119	\N	\N	66.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6753.webp	t	\N	f
2178	New Holland T9.450	New Holland	T9.450	2011	405	\N	22453	177.2	4x4	Diagonal 1-3	25	119	\N	\N	82.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6754.webp	t	\N	f
2179	New Holland T9.505	New Holland	T9.505	2011	457	\N	22453	174.1	4x4	Diagonal 1-3	25	119	\N	\N	90.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6755.webp	t	\N	f
2180	New Holland T9.560	New Holland	T9.560	2011	507	\N	22453	158.8	4x4	Diagonal 1-3	25	119	\N	\N	103.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6756.webp	t	\N	f
663	John Deere 6100	John Deere	6100	1992	75	\N	3900	27.5	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6810.webp	f	\N	f
287	John Deere 6200 (1992-1997)	John Deere	6200	1992	84	\N	3764	30.8	4x4	Radial 16.9R34	429	1593	\N	\N	14.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6811.webp	t	\N	f
288	John Deere 6300 (1992-1997)	John Deere	6300	1992	90	\N	4050	33	4x4	Radial 16.9R38	429	1695	\N	\N	16.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6812.webp	t	\N	f
289	John Deere 6400 (1992-1997)	John Deere	6400	1992	100	\N	4100	36.7	4x4	Radial 16.9R38	429	1695	\N	\N	17.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6813.webp	t	\N	f
2181	New Holland T9.615	New Holland	T9.615	2011	542	\N	25401	207.2	4x4	Diagonal 1-3	25	119	\N	\N	104.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6757.webp	t	\N	f
2182	New Holland T9.670	New Holland	T9.670	2011	608	\N	25401	215	4x4	Diagonal 1-3	25	119	\N	\N	104.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6758.webp	t	\N	f
656	John Deere 3100	Renault	deere 3100	1995	55	\N	2970	20.2	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6779.webp	f	\N	f
657	John Deere 3200	Renault	deere 3200	1995	65	\N	3230	23.8	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6780.webp	f	\N	f
658	John Deere 3300	Renault	deere 3300	1995	75	\N	3480	27.5	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6781.webp	f	\N	f
659	John Deere 3400	Renault	deere 3400	1995	85	\N	3480	31.2	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6782.webp	t	\N	f
2183	New Holland 4635	New Holland	4635	1996	60	\N	3270	22	4x4	Diagonal 7.50-16	191	730	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6783.webp	f	\N	f
2187	Kubota M126X Power Krawler	Kubota	M126X Power Krawler	2009	125	\N	5200	39.6	track	Diagonal 09 - 20	229	897	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6798.webp	t	\N	f
1952	Ford 8730	Ford	8730	1990	140	\N	5799	69.5	4x4	Diagonal 15-38	381	1613	\N	\N	34.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5967.webp	t	\N	f
1953	Ford 8770	Ford	8770	1993	190	\N	7529	0.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5968.webp	t	\N	f
667	John Deere 7200R	John Deere	7200R	2011	200	\N	10469	91.8	4x4	Diagonal 11 - 20	279	983	\N	\N	42	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6854.webp	t	\N	f
664	John Deere 6506	John Deere	6506	1995	105	\N	4649	38.5	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6818.webp	f	\N	f
665	John Deere 6110D	John Deere	6110D	2000	106	\N	3870	33	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6846.webp	t	\N	f
666	John Deere 6125D	John Deere	6125D	2000	123	\N	3870	38.5	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6847.webp	t	\N	f
681	John Deere 6930 Premium	John Deere	6930 Premium	2006	155	\N	5878	49.9	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7002.webp	t	\N	f
2226	Massey Ferguson 415	Massey Ferguson	415	2001	46	\N	2209	14.6	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7055.webp	f	\N	f
2227	Massey Ferguson 425	Massey Ferguson	425	2001	65	\N	2869	20.1	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7057.webp	f	\N	f
2228	Massey Ferguson 435	Massey Ferguson	435	2001	72	\N	2869	22.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7058.webp	f	\N	f
2229	Massey Ferguson 440	Massey Ferguson	440	2001	82	\N	3040	25.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7060.webp	f	\N	f
2230	Massey Ferguson 460	Massey Ferguson	460	2001	105	\N	3939	33.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7061.webp	t	\N	f
2231	Massey Ferguson 465	Massey Ferguson	465	2001	120	\N	4209	37.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7062.webp	f	\N	f
2232	Massey Ferguson 475	Massey Ferguson	475	2001	130	\N	4520	40.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7063.webp	t	\N	f
2233	Massey Ferguson 425 Xtra	Massey Ferguson	425 Xtra	2000	65	\N	2869	23.8	4x2	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7064.webp	f	\N	f
2234	Massey Ferguson 435 Xtra	Massey Ferguson	435 Xtra	2001	72	\N	2869	26.4	4x2	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7065.webp	f	\N	f
2235	Massey Ferguson 440 Xtra	Massey Ferguson	440 Xtra	2001	82	\N	3040	30.1	4x2	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7066.webp	f	\N	f
2236	Massey Ferguson 455 Xtra	Massey Ferguson	455 Xtra	2000	100	\N	4070	36.7	4x2	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7067.webp	t	\N	f
2237	Massey Ferguson 460 Xtra	Massey Ferguson	460 Xtra	2001	110	\N	4209	40.4	4x2	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7068.webp	t	\N	f
2238	Massey Ferguson 470 Xtra	Massey Ferguson	470 Xtra	2001	120	\N	4209	44	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7069.webp	t	\N	f
2239	Massey Ferguson 480 Xtra	Massey Ferguson	480 Xtra	2001	130	\N	4209	47.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7070.webp	t	\N	f
3547	J.I. Case 20-40	Case IH	20 40	1912	40	\N	6305	24.6	4x2	Diagonal 66x20	1676	3358	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7081.webp	f	\N	f
3548	J.I. Case 30-60	Case IH	30 60	1912	60	\N	11702	22	4x2	Diagonal 72x24	1829	3719	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7082.webp	f	\N	f
3549	J.I. Case 22-40	Case IH	22 40	1919	40	\N	4626	22.1	4x2	Diagonal 56x16	1422	2824	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7083.webp	f	\N	f
3550	J.I. Case 40-72	Case IH	40 72	1921	72	\N	9616	47.5	4x2	Diagonal 72x20	1829	3617	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7084.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1106/	f
3551	J.I. Case 18-32	Case IH	18 32	1924	32	\N	2948	17.3	4x2	Diagonal 52x14	1321	2601	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7085.webp	f	\N	f
3553	J.I. Case 12-20	Case IH	12 20	1921	20	\N	1919	14	4x2	Diagonal 42x12	1067	2118	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7087.webp	f	\N	f
1951	Ford 8670	Ford	8670	1993	170	\N	7166	77.3	4x4	Diagonal 93 - 20	2362	4524	\N	\N	34.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5966.webp	t	\N	f
668	John Deere 7215R	John Deere	7215R	2011	215	\N	11945	91.9	4x4	Diagonal 11 - 20	279	983	\N	\N	44.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6855.webp	t	\N	f
683	John Deere 9360R	John Deere	9360R	2012	360	\N	15612	160.5	4x4	Diagonal 12 - 20	305	1026	\N	\N	72.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7095.webp	t	\N	f
684	John Deere 9410R	John Deere	9410R	2012	410	\N	17264	162.1	4x4	Diagonal 12 - 20	305	1026	\N	\N	80.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7096.webp	t	\N	f
685	John Deere 9460R	John Deere	9460R	2012	460	\N	17694	192.9	4x4	Diagonal 12 - 20	305	1026	\N	\N	80.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7097.webp	t	\N	f
686	John Deere 9510R	John Deere	9510R	2012	510	\N	18842	199.8	4x4	Diagonal 12 - 20	305	1026	\N	\N	79.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7098.webp	t	\N	f
1978	Massey Ferguson 1529	Iseki	ferguson 1529	2007	28.4	\N	1169	8.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6086.webp	f	\N	f
1979	Massey Ferguson 1532	Iseki	ferguson 1532	2007	32.5	\N	1174	9.7	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6087.webp	f	\N	f
1980	New Holland 4330V	New Holland	4330V	1997	70	\N	1869	22.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td609.webp	f	\N	f
627	John Deere 4010	John Deere	4010	1960	80	\N	2959	31.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	27.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td61.webp	f	https://digitalcommons.unl.edu/tractormuseumlit/1386/	f
1981	Ford 4430	Fiat	4430	1992	70	\N	2399	25.7	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td610.webp	f	\N	f
1982	Ford 3830	Fiat	3830	1992	45	\N	1830	16.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td611.webp	f	\N	f
1983	New Holland 4630	New Holland	4630	1994	60	\N	2749	21.5	4x4	Diagonal 13.6-28	345	1298	\N	\N	14	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td613.webp	t	\N	f
1985	New Holland 5030	New Holland	5030	1992	62	\N	2909	34.5	4x4	Diagonal 13.6-36	345	1502	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td615.webp	f	\N	f
1986	Ford 5530	Ford	5530	1992	62	\N	3306	22.7	4x4	Diagonal 13.6x38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td616.webp	f	\N	f
1988	New Holland 5610S	New Holland	5610S	1994	75	\N	2566	24.2	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td618.webp	f	\N	f
630	John Deere 4025	John Deere	4025	1969	94	\N	3880	34.5	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6304.webp	f	\N	f
3513	Fiat 55-76	Fiat	55 76	1990	54.2	\N	1809	16.5	4x4	Diagonal 9.5-28	241	1121	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6067.webp	f	\N	f
3515	Fiat 70-76	Fiat	70 76	1990	69.1	\N	2370	22.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6074.webp	f	\N	f
3516	Fiat 80-76	Fiat	80 76	1990	78.9	\N	2390	25.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td6077.webp	f	\N	f
1984	New Holland 4835	New Holland	4835	1996	65	\N	3200	20.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td614.webp	f	\N	f
2009	CaseIH JX60	Turk Tractor	jx60	2007	55	\N	2336	16.5	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6305.webp	f	\N	f
2010	CaseIH JX70	Turk Tractor	jx70	2007	62	\N	2336	19.1	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6306.webp	t	\N	f
2011	CaseIH JX80	Turk Tractor	jx80	2007	72	\N	2586	22.7	4x4	Diagonal 07 - 20	178	810	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6307.webp	f	\N	f
687	John Deere 9560R	John Deere	9560R	2012	560	\N	18842	195.7	4x4	Diagonal 12 - 20	305	1026	\N	\N	79.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7099.webp	t	\N	f
2248	Massey Ferguson 3125	Massey Ferguson	3125	1990	123.4	\N	5210	45.3	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7146.webp	t	\N	f
717	John Deere 6210R (2011-2014)	John Deere	6210R	2011	210	\N	7401	77	4x4	Diagonal 12 - 20	305	1026	\N	\N	43.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7161.webp	t	\N	f
2012	CaseIH Farmall 70	Turk Tractor	farmall 70	2008	65	\N	2336	27.1	4x4	Diagonal 08 - 20	203	853	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6309.webp	t	\N	f
715	John Deere 6170R (2011-2014)	John Deere	6170R	2011	170	\N	7351	62.4	4x4	Diagonal 12 - 20	305	1026	\N	\N	34.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7159.webp	t	\N	f
716	John Deere 6190R (2011-2014)	John Deere	6190R	2011	190	\N	7376	69.7	4x4	Diagonal 12 - 20	305	1026	\N	\N	40.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7160.webp	t	\N	f
2251	CaseIH Farmall 110A	CaseIH	Farmall 110A	2012	110	\N	3920	33.9	4x4	Diagonal 12 - 20	305	1026	\N	\N	22.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7181.webp	t	\N	f
2253	CaseIH Farmall 125A	CaseIH	Farmall 125A	2012	125	\N	4399	38	4x4	Diagonal 12 - 20	305	1026	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7183.webp	t	\N	f
721	John Deere 6225	John Deere	6225	2000	94	\N	3779	28.6	4x2	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7175.webp	t	\N	f
722	John Deere 6325	John Deere	6325	2000	105	\N	3779	32.3	4x2	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7176.webp	t	\N	f
2252	CaseIH Farmall 120A	CaseIH	Farmall 120A	2012	118	\N	3999	34.2	4x4	Diagonal 12 - 20	305	1026	\N	\N	23.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7182.webp	t	\N	f
723	John Deere 6425	John Deere	6425	2000	114	\N	3779	36	4x2	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7177.webp	t	\N	f
724	John Deere 6525	John Deere	6525	2000	120	\N	4360	37.4	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7178.webp	t	\N	f
2249	New Holland Boomer 20	New Holland	Boomer 20	2012	23	\N	772	6.1	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7179.webp	f	\N	f
2250	New Holland Boomer 25	New Holland	Boomer 25	2012	27	\N	772	7.3	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7180.webp	f	\N	f
2118	New Holland TD5030 (2008-2014)	Turk Tractor	holland td5030	2008	82	\N	3349	21.3	4x4	Radial 16.9R30	429	1492	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7185.webp	t	\N	f
2255	New Holland T4.55	New Holland	T4.55	2000	55	\N	2669	20.2	4x4	Radial 340/85R28	340	1289	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7191.webp	t	\N	f
2254	New Holland T4.75 (2012-2014)	New Holland	T4.75	2012	74	\N	2669	27.1	4x4	Radial 480/70R30	480	1434	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7193.webp	t	\N	f
725	John Deere 4000	John Deere	4000	1969	96.89	\N	3365	36.5	4x2	Diagonal 16.9-34	429	1593	\N	\N	23.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td72.webp	f	\N	f
2257	Kubota L4300	Kubota	L4300	2001	45.3	\N	1290	13.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7209.webp	f	\N	f
2258	Kubota L4600	Kubota	L4600	2011	46.3	\N	1445	13.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7210.webp	f	\N	f
642	John Deere 5100M (2012-2022)	John Deere	5100M	2012	100	\N	3447	34.5	4x4	Radial 18.4R30	467	1557	\N	\N	19.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7217.webp	t	\N	f
726	John Deere 5115M	John Deere	5115M	2012	115	\N	3583	39.1	4x4	Diagonal 14.9-28	378	1355	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7218.webp	t	\N	f
2259	Ford TW-15	Ford	TW 15	1983	140	\N	5150	58.9	4x4	Diagonal 20.8-38	528	1863	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td722.webp	t	\N	f
3554	J.I. Case 600	Case IH	600	1953	70	\N	3402	25.7	4x2	Diagonal 15-34	381	1511	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7229.webp	f	\N	f
727	John Deere 2130	John Deere	2130	1973	79.1	\N	2712	22.2	4x2	Diagonal 15.5-38	394	1634	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td723.webp	f	\N	f
2828	CaseIH Maxxum 100	CaseIH	maxxum 100	2007	99	\N	4790	36.3	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7233.webp	t	\N	f
267	John Deere 7720 (2003-2006)	John Deere	7720	2003	172.9	\N	7851	51.4	4x4	Radial 480/80R42	480	1835	\N	\N	32.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7244.webp	t	\N	f
268	John Deere 7820 (2003-2006)	John Deere	7820	2003	189.1	\N	7851	56.9	4x4	Radial 480/80R42	480	1835	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7245.webp	t	\N	f
269	John Deere 7920 (2003-2006)	John Deere	7920	2003	205.2	\N	8131	62.4	4x4	Radial 480/80R46	480	1936	\N	\N	40.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7246.webp	t	\N	f
2827	CaseIH Farmall 140A	CaseIH	Farmall 140A	2012	140	\N	4399	40.2	4x4	Diagonal 12 - 20	305	1026	\N	\N	28.8	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7184.webp	t	\N	f
2061	New Holland TD5050 (2008-2014)	Turk Tractor	holland td5050	2008	93	\N	3539	33	4x4	Diagonal 09 - 20	229	897	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7186.webp	t	\N	f
1181	New Holland Workmaster 65 (2009-2014)	New Holland	Workmaster 65	2009	65	\N	2580	22.6	4x4	Diagonal 16.9-30	429	1492	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7190.webp	f	\N	f
2260	Kubota B1410	Kubota	B1410	2000	13.8	\N	509	4	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7241.webp	f	\N	f
2261	Kubota B1610	Kubota	B1610	2000	15.7	\N	522	4.5	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7242.webp	f	\N	f
728	Massey Ferguson 25	Massey Ferguson	25	1963	25	\N	1412	14.1	4x2	Diagonal 10-28	254	1143	\N	\N	6.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td726.webp	f	\N	f
2263	New Holland TC24D	New Holland	TC24D	1999	24	\N	781	7.2	4x4	Diagonal 9.5x16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7267.webp	f	\N	f
2264	New Holland TC35A	New Holland	TC35A	2003	35	\N	1262	10.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7268.webp	f	\N	f
729	John Deere 1025R	John Deere	1025R	2013	23.8	\N	654	6.6	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7277.webp	f	\N	f
2265	Kubota MX5000SU	Kubota	MX5000SU	2006	52.2	\N	1490	16.1	4x2	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7278.webp	f	\N	f
731	John Deere 2032R	John Deere	2032R	2013	31.7	\N	894	8.6	4x4	Diagonal 14-17.5	356	1049	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7283.webp	f	\N	f
2273	Massey Ferguson 95	Minneapolis-Moline	ferguson 95	1958	63	\N	3356	23.1	4x2	Diagonal 15-34	381	1511	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7294.webp	f	\N	f
2830	CaseIH Farmall 105C	CaseIH	Farmall 105C	2013	106	\N	3600	34.7	4x4	Radial 16.9R34	429	1593	\N	\N	22.7	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7298.webp	t	\N	f
236	John Deere 4520 (1969-1970)	John Deere	4520	1969	120	\N	5572	61.3	4x2	Diagonal 20.8-38	528	1863	\N	\N	30.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td73.webp	t	\N	f
733	Massey Ferguson F40	Massey Ferguson	F40	1956	31	\N	1406	11.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td730.webp	f	\N	f
2275	Massey Ferguson GC1705	Iseki	ferguson gc1705	2013	22.5	\N	650	6.9	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7301.webp	f	\N	f
2276	Massey Ferguson GC1715	Iseki	ferguson gc1715	2013	25	\N	650	7.2	4x4	Diagonal 26x12.00-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7302.webp	f	\N	f
2277	Kubota BX1870	Kubota	BX1870	2013	18	\N	610	5	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7303.webp	f	\N	f
2278	Kubota BX2370	Kubota	BX2370	2013	23	\N	639	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7304.webp	f	\N	f
734	Massey Ferguson 50	Massey Ferguson	50	1957	38	\N	1653	23.6	4x2	Diagonal 12.4-28	315	1247	\N	\N	12.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td732.webp	f	\N	f
3555	Zetor 6011	Zetor	6011	1980	60	\N	3020	22	4x2	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7327.webp	f	\N	f
3556	Zetor 6045	Zetor	6045	1980	60	\N	3430	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7328.webp	f	\N	f
3557	Zetor 7011	Zetor	7011	1980	70	\N	3020	21.5	4x2	Diagonal 14-30	356	1367	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7329.webp	f	\N	f
3558	Zetor 7045	Zetor	7045	1980	70	\N	3430	22	4x4	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7330.webp	f	\N	f
735	Massey Ferguson 65	Massey Ferguson	65	1958	54.5	\N	1898	30.4	4x2	Diagonal 11-38	279	1440	\N	\N	18.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td734.webp	f	\N	f
3560	Belarus 5150	Belarus	5150	1994	53	\N	3569	19.4	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7340.webp	f	\N	f
3561	Belarus 5160	Belarus	5160	1994	65	\N	3243	23.8	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7341.webp	f	\N	f
3562	Belarus 5170	Belarus	5170	1994	74	\N	3299	27.1	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7342.webp	f	\N	f
3563	Belarus 5180	Belarus	5180	1994	85	\N	3719	31.2	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7343.webp	t	\N	f
3564	Belarus 5190	Belarus	5190	1994	93	\N	3719	34.1	4x4	Diagonal 16.9x38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7344.webp	t	\N	f
3565	Belarus 6100	Belarus	6100	1994	100	\N	4249	36.7	4x4	Diagonal 16.9x38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7345.webp	t	\N	f
3566	Belarus 5260	Belarus	5260	1997	65	\N	3243	23.8	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7346.webp	f	\N	f
3567	Belarus 5270	Belarus	5270	1997	74	\N	3664	27.1	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7347.webp	f	\N	f
3568	Belarus 5280	Belarus	5280	1997	85	\N	3685	31.2	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7348.webp	t	\N	f
2267	New Holland T6030 Delta	New Holland	T6030 Delta	2007	115	\N	4699	45.5	4x4	Diagonal 07 - 20	178	810	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7286.webp	t	\N	f
2268	New Holland T6050 Delta	New Holland	T6050 Delta	2007	125	\N	4699	46.2	4x4	Diagonal 07 - 20	178	810	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7287.webp	t	\N	f
2269	New Holland T6020 Plus	New Holland	T6020 Plus	2007	110	\N	4709	48.2	4x4	Diagonal 07 - 20	178	810	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7288.webp	t	\N	f
2270	New Holland T6030 Plus	New Holland	T6030 Plus	2007	115	\N	5142	47.9	4x4	Diagonal 07 - 20	178	810	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7289.webp	t	\N	f
2271	New Holland T6050 Plus	New Holland	T6050 Plus	2007	125	\N	5142	48.9	4x4	Diagonal 07 - 20	178	810	\N	\N	26.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7290.webp	t	\N	f
2272	New Holland T6070 Plus	New Holland	T6070 Plus	2007	140	\N	5142	57.8	4x4	Diagonal 07 - 20	178	810	\N	\N	29.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7291.webp	t	\N	f
2280	Kubota L2601	Kubota	L2601	1976	25.6	\N	1015	9.4	4x4	Diagonal 10-24	254	1041	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7311.webp	f	\N	f
3559	Fiat 460	Fiat	460	2000	48	\N	2330	17.6	4x4	Diagonal 12-28	305	1229	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7338.webp	f	\N	f
2084	Ford 5000 Diesel	Ford	5000 Diesel	1962	51.8	\N	2519	36.1	4x2	Diagonal 16.9-30	429	1492	\N	\N	11.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6440.webp	f	\N	f
2085	New Holland 8560	New Holland	8560	1996	130	\N	5618	52.5	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td645.webp	t	\N	f
2839	CaseIH Steiger 420	CaseIH	steiger 420	2014	426	\N	18216	185.8	4x4	Radial 710/70R42	710	2061	\N	\N	85.2	\N	available	2026-09-30 16:51:28.845746	https://cdn.dealerspike.com/imglib/v1/800x600/imglib/Assets/Inventory/B7/72/B7720CB8-8801-4E83-8A37-2477AC856D2B.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
736	Massey Ferguson 85	Massey Ferguson	85	1959	62.21	\N	2602	39	4x2	Diagonal 15x30	381	1410	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td736.webp	f	\N	f
2282	Massey Ferguson 4609	Massey Ferguson	4609	2013	90	\N	2900	26.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7369.webp	t	\N	f
737	Massey Ferguson 88	Massey Ferguson	88	1959	63	\N	3250	39.9	4x2	Diagonal 15x30	381	1410	\N	\N	17	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td737.webp	f	\N	f
2283	Massey Ferguson 4610	Massey Ferguson	4610	2013	100	\N	2949	29.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7370.webp	t	\N	f
2284	CaseIH Farmall 115U	CaseIH	Farmall 115U	2013	115	\N	4250	36.6	4x4	Radial 18.4R34	467	1658	\N	\N	23.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td738.webp	t	\N	f
2281	Massey Ferguson 4608	Massey Ferguson	4608	2013	80	\N	2750	23.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7368.webp	t	\N	f
614	John Deere 8245R (2014-2019)	John Deere	8245R	2014	245	\N	14828	0.7	4x4	Radial 480/80R50	480	2038	\N	\N	47.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7383.webp	t	\N	f
742	John Deere 8270R (2014-2019)	John Deere	8270R	2014	270	\N	14828	111.2	4x4	Radial 480/80R50	480	2038	\N	\N	51.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7384.webp	t	\N	f
743	John Deere 8295R (2014-2019)	John Deere	8295R	2014	295	\N	14828	115.5	4x4	Radial 480/80R50	480	2038	\N	\N	56	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7385.webp	t	\N	f
744	John Deere 8320R (2014-2019)	John Deere	8320R	2014	320	\N	18000	124.2	4x4	Radial 480/80R50	480	2038	\N	\N	56	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7386.webp	t	\N	f
615	John Deere 8345R (2014-2019)	John Deere	8345R	2014	345	\N	18000	106.8	4x4	Radial 480/80R50	480	2038	\N	\N	65.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7387.webp	t	\N	f
745	John Deere 8370R	John Deere	8370R	2014	370	\N	18000	126.8	4x4	Radial 480/80R50	480	2038	\N	\N	73.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7388.webp	t	\N	f
746	Massey Ferguson 97	Minneapolis-Moline	ferguson 97	1962	112	\N	3699	37.1	4x4	Diagonal 23.1-26	587	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td739.webp	f	\N	f
235	John Deere 4320 (1971-1972)	John Deere	4320	1971	115	\N	4105	52.4	4x2	Diagonal 18.4-34	467	1658	\N	\N	30.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td74.webp	t	\N	f
747	Massey Ferguson 98	Oliver	ferguson 98	1960	84.1	\N	6804	30.9	4x2	Diagonal 15-34	381	1511	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td740.webp	f	\N	f
3574	J.I. Case 995	Case IH	995	1976	62	\N	2354	32.5	4x2	Diagonal 91 - 19	2311	4412	\N	\N	14	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7372.webp	f	\N	f
2111	New Holland 8870	New Holland	8870	1993	210	\N	7575	82.5	4x4	Diagonal 93 - 20	2362	4524	\N	\N	37.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6627.webp	t	\N	f
2112	New Holland 8970	New Holland	8970	1993	240	\N	7688	124.6	4x4	Diagonal 93 - 20	2362	4524	\N	\N	43.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6628.webp	t	\N	f
2288	New Holland T4.115	New Holland	T4.115	2013	114	\N	3379	38	4x4	Diagonal 13 - 20	330	1069	\N	\N	22.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7414.webp	f	\N	f
2289	Kubota L3560	Kubota	L3560	2013	37	\N	1584	10.8	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7416.webp	f	\N	f
2113	New Holland Workmaster 45	New Holland	Workmaster 45	2009	45	\N	1599	14.3	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6647.webp	f	\N	f
1180	New Holland Workmaster 55 (2009-2014)	New Holland	Workmaster 55	2009	55	\N	1710	18.1	4x4	Diagonal 14.9x28	378	1355	\N	\N	13.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6648.webp	t	\N	f
1182	New Holland Workmaster 75 (2010-2014)	New Holland	Workmaster 75	2010	75	\N	2580	25	4x4	Diagonal 16.9x30	429	1492	\N	\N	16.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6649.webp	t	\N	f
2290	Kubota L4060	Kubota	L4060	2013	42	\N	1700	12.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7417.webp	f	\N	f
2291	Kubota L4760	Kubota	L4760	2013	49	\N	1744	15	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7418.webp	f	\N	f
2292	Kubota L5060	Kubota	L5060	2013	52	\N	1804	16.1	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7419.webp	t	\N	f
2293	Kubota L5460	Kubota	L5460	2013	56	\N	1809	17.1	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7420.webp	t	\N	f
2294	Kubota L6060	Kubota	L6060	2013	62	\N	1809	19.4	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7421.webp	t	\N	f
2295	Kubota M6060	Kubota	M6060	2007	63.5	\N	2370	20.5	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7422.webp	t	\N	f
2296	Kubota M7060	Kubota	M7060	2007	71	\N	2380	23.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7423.webp	t	\N	f
2297	Kubota M8560	Kubota	M8560	2013	85.5	\N	2639	27.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7424.webp	t	\N	f
2298	Kubota M9960	Kubota	M9960	2013	100	\N	2698	33.4	4x4	Diagonal 18.4-30	467	1557	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7425.webp	t	\N	f
2299	Massey Ferguson 1736	Massey Ferguson	ferguson 1736	2013	36.2	\N	1525	10.1	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7426.webp	t	\N	f
2300	Massey Ferguson 1742	Massey Ferguson	ferguson 1742	2013	41.6	\N	1650	12	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7427.webp	t	\N	f
2301	Massey Ferguson 1749	Massey Ferguson	ferguson 1749	2013	48.3	\N	1774	14.3	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7428.webp	t	\N	f
2302	Massey Ferguson 1754	Massey Ferguson	ferguson 1754	2013	53.6	\N	1880	15.4	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7429.webp	t	\N	f
2114	New Holland TS6020	New Holland	TS6020	2010	110	\N	3816	35.3	4x4	Diagonal 10 - 20	254	940	\N	\N	23.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6650.webp	t	\N	f
2303	Massey Ferguson 1758	Massey Ferguson	ferguson 1758	2013	59	\N	1895	16.3	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7430.webp	t	\N	f
2304	Massey Ferguson 1759	Massey Ferguson	ferguson 1759	2013	59	\N	1969	16.7	4x4	Diagonal 16.9x26	429	1390	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7431.webp	t	\N	f
2305	Massey Ferguson 1734E	Massey Ferguson	ferguson 1734e	2013	34	\N	1240	10.6	4x4	Diagonal 15x19.5	381	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7432.webp	t	\N	f
2115	New Holland TS6030	New Holland	TS6030	2010	118	\N	3816	36.5	4x4	Diagonal 10 - 20	254	940	\N	\N	23.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6651.webp	t	\N	f
2285	New Holland T4.85	New Holland	T4.85	2013	84	\N	3379	28.1	4x4	Diagonal 13 - 20	330	1069	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7411.webp	f	\N	f
2286	New Holland T4.95	New Holland	T4.95	2013	98	\N	3379	30.3	4x4	Diagonal 13 - 20	330	1069	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7412.webp	f	\N	f
2287	New Holland T4.105	New Holland	T4.105	2013	106	\N	3379	34.6	4x4	Diagonal 13 - 20	330	1069	\N	\N	22.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7413.webp	f	\N	f
748	Massey Ferguson 130	Massey Ferguson	130	1966	30	\N	1456	15.3	4x2	Diagonal 12.4-28	315	1247	\N	\N	7.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td742.webp	f	\N	f
647	John Deere 8235R	John Deere	8235R	2011	235	\N	12346	105.1	4x4	Diagonal 1-3	25	119	\N	\N	47.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6712.webp	t	\N	f
2140	Massey Ferguson 5425	Massey Ferguson	5425	2008	80	\N	4172	35.6	4x4	Radial 420/85R34	420	1578	\N	\N	18.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6690.webp	t	\N	f
2141	Massey Ferguson 5475	Massey Ferguson	5475	2008	135	\N	5400	52.8	4x4	Radial 460/85R34	460	1646	\N	\N	29.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6696.webp	t	\N	f
2142	Massey Ferguson 5480	Massey Ferguson	5480	2008	140	\N	4287	49.5	4x4	Radial 460/85R34	460	1646	\N	\N	29.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6697.webp	t	\N	f
646	John Deere 2510	John Deere	2510	1965	54.9	\N	3059	26.9	4x2	Diagonal 13.6-38	345	1552	\N	\N	18.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td67.webp	f	\N	f
366	John Deere 2520 (1968-1972)	John Deere	2520	1968	61.29	\N	3367	29.6	4x2	Diagonal 13.6-38	345	1552	\N	\N	15.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td71.webp	f	\N	f
2306	Massey Ferguson 1739E	Massey Ferguson	ferguson 1739e	2013	39.5	\N	1250	12	4x4	Diagonal 15x19.5	381	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7433.webp	t	\N	f
2307	Massey Ferguson 7140	Massey Ferguson	7140	2000	140	\N	7702	51.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7434.webp	t	\N	f
2308	Massey Ferguson 7150	Massey Ferguson	7150	2000	150	\N	8250	55	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7435.webp	t	\N	f
2309	Massey Ferguson 7170	Massey Ferguson	7170	2000	170	\N	9348	62.4	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7436.webp	t	\N	f
2310	Massey Ferguson 7180	Massey Ferguson	7180	2000	180	\N	9938	66	4x4	Diagonal 710/65-38	710	1888	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7437.webp	t	\N	f
750	Massey Ferguson 150	Massey Ferguson	150	1964	45.5	\N	2179	21.3	4x2	Diagonal 12x28	305	1229	\N	\N	7.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td744.webp	f	\N	f
751	Massey Ferguson 154-4	Landini	ferguson 154 4	1980	50	\N	2347	22.8	4x4	Diagonal 12-28	305	1229	\N	\N	9.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td745.webp	f	\N	f
752	Massey Ferguson 165 (1964-1975)	Massey Ferguson	165	1964	58.3	\N	2270	25.4	4x2	Diagonal 11-32	279	1288	\N	\N	11.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td746.webp	f	\N	f
34	John Deere 3033R (2005-2013)	John Deere	3033R	2005	31.8	\N	1315	9.1	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7463.webp	f	\N	f
2160	CaseIH Puma 130	CaseIH	Puma 130	2011	131	\N	6168	54.4	4x4	Diagonal 11 - 20	279	983	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6736.webp	t	\N	f
690	John Deere 9560RT	John Deere	9560RT	2012	560	\N	20371	214.6	track	Diagonal 12 - 20	305	1026	\N	\N	77.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7102.webp	t	\N	f
756	Massey Ferguson 175	Massey Ferguson	175	1964	63	\N	2687	31.6	4x2	Diagonal 14-28	356	1316	\N	\N	14.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td748.webp	f	\N	f
2161	CaseIH Puma 145	CaseIH	Puma 145	2011	146	\N	6509	60.2	4x4	Diagonal 11 - 20	279	983	\N	\N	29.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6737.webp	t	\N	f
2163	CaseIH Puma 170	CaseIH	Puma 170	2011	167	\N	6725	76.5	4x4	Diagonal 11 - 20	279	983	\N	\N	33.3	\N	available	2026-09-30 16:49:10.296204	https://cnhi-p-001-delivery.sitecorecontenthub.cloud/api/public/content/6bebf799bb274c3ba07a77ac2136694c?v=968024ac	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/2023/CIH_FOLLETO_TRACTOR_PUMA_SWB.pdf#page=9	t
691	John Deere 7185J	John Deere	7185J	2000	185	\N	8101	57.6	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7103.webp	t	\N	f
753	John Deere 3039R	John Deere	3039R	2005	38.2	\N	1315	11.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7464.webp	t	\N	f
754	John Deere 3046R	John Deere	3046R	2005	44.7	\N	1315	12.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7465.webp	t	\N	f
3585	Challenger MT645D	Challenger	mt645d	2011	240	\N	10999	114.3	4x4	Radial 520/85R46	520	2052	\N	\N	50.7	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7466.webp	t	\N	f
3586	Challenger MT655D	Challenger	mt655d	2011	265	\N	10999	106.1	4x4	Radial 520/85R46	520	2052	\N	\N	55.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7467.webp	t	\N	f
3587	Challenger MT665D	Challenger	mt665d	2011	290	\N	10999	110.7	4x4	Radial 520/85R46	520	2052	\N	\N	60.2	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7468.webp	t	\N	f
3588	Challenger MT675D	Challenger	mt675d	2011	320	\N	10999	113.3	4x4	Radial 520/85R46	520	2052	\N	\N	65.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7469.webp	t	\N	f
755	Massey Ferguson 174S	Massey Ferguson	174S	1986	57	\N	2265	20.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td747.webp	f	\N	f
3589	Challenger MT685D	Challenger	mt685d	2011	340	\N	10999	112	4x4	Radial 520/85R46	520	2052	\N	\N	66.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7470.webp	t	\N	f
2320	Massey Ferguson 251XE	Massey Ferguson	251XE	2001	48	\N	2375	16.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7474.webp	f	\N	f
3592	Challenger MT555D	Challenger	mt555d	2012	170	\N	7711	75	4x4	Radial 480/80R42	480	1835	\N	\N	35.6	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7480.webp	t	\N	f
3593	Challenger MT565D	Challenger	mt565d	2012	180	\N	7711	75.6	4x4	Radial 480/80R42	480	1835	\N	\N	37.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7481.webp	t	\N	f
3594	Challenger MT575D	Challenger	mt575d	2012	200	\N	7711	75.8	4x4	Radial 480/80R42	480	1835	\N	\N	40.9	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7482.webp	t	\N	f
3595	Challenger MT585D	Challenger	mt585d	2012	220	\N	7711	74.5	4x4	Radial 480/80R46	480	1936	\N	\N	43.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7483.webp	t	\N	f
2162	CaseIH Puma 160	CaseIH	Puma 160	2011	160	\N	7420	61.9	4x4	Diagonal 11 - 20	279	983	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6738.webp	t	\N	f
688	John Deere 9460RT	John Deere	9460RT	2012	460	\N	20371	203.6	track	Diagonal 12 - 20	305	1026	\N	\N	78.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7100.webp	t	\N	f
689	John Deere 9510RT	John Deere	9510RT	2012	510	\N	20371	214.5	track	Diagonal 12 - 20	305	1026	\N	\N	78	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7101.webp	t	\N	f
758	John Deere 4620	John Deere	4620	1971	135	\N	5887	64.4	4x2	Diagonal 20.8-38	528	1863	\N	\N	34.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td75.webp	t	\N	f
759	Massey Ferguson 205	Toyosha	ferguson 205	1978	20	\N	941	11.1	4x4	Diagonal 13.6-16	345	994	\N	\N	4.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td750.webp	f	\N	f
2326	New Holland Workmaster 35	New Holland	Workmaster 35	2013	33	\N	1315	10.4	4x4	Diagonal 13 - 20	330	1069	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7503.webp	f	\N	f
760	Massey Ferguson 210	Hinomoto	ferguson 210	1978	25	\N	1179	9.6	4x4	Diagonal 13.6-16	345	994	\N	\N	6.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td751.webp	f	\N	f
761	Massey Ferguson 220	Toyosha	ferguson 220	1978	31	\N	1417	14.6	4x4	Diagonal 13.6-16	345	994	\N	\N	7.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td752.webp	f	\N	f
762	Massey Ferguson 230	Massey Ferguson	230	1976	38	\N	1451	17.9	4x2	Diagonal 12.4-28	315	1247	\N	\N	7.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td753.webp	f	\N	f
763	John Deere 6105M	John Deere	6105M	2013	105	\N	8700	47.7	4x4	Radial 460/85R34	460	1646	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7530.webp	t	\N	f
764	John Deere 6115M	John Deere	6115M	2013	115	\N	5210	46.7	4x4	Radial 460/85R34	460	1646	\N	\N	24.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7531.webp	t	\N	f
765	John Deere 6125M	John Deere	6125M	2013	125	\N	5225	48.2	4x4	Radial 460/85R34	460	1646	\N	\N	25.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7532.webp	t	\N	f
81	John Deere 6140M (2013-2015)	John Deere	6140M	2013	140	\N	5533	51.6	4x4	Radial 460/85R38	460	1747	\N	\N	26.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7533.webp	t	\N	f
766	John Deere 6150M	John Deere	6150M	2013	150	\N	5929	59.5	4x4	Radial 460/85R38	460	1747	\N	\N	29.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7534.webp	t	\N	f
767	John Deere 6170M	John Deere	6170M	2013	170	\N	7105	64	4x4	Radial 460/85R38	460	1747	\N	\N	32.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7535.webp	t	\N	f
768	Massey Ferguson 231	Massey Ferguson	231	1989	38	\N	1843	12.5	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td754.webp	f	\N	f
769	John Deere 6105D	John Deere	6105D	2013	105	\N	4150	33.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7540.webp	t	\N	f
719	John Deere 6140R (2013-2014)	John Deere	6140R	2013	140	\N	6615	63.4	4x4	Radial 480/80R46	480	1936	\N	\N	28.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7544.webp	t	\N	f
720	John Deere 6150R (2013-2014)	John Deere	6150R	2013	150	\N	6792	61.8	4x4	Radial 480/80R46	480	1936	\N	\N	31	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7545.webp	t	\N	f
770	Massey Ferguson 231S	Massey Ferguson	231S	1999	45	\N	1868	15.4	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td755.webp	f	\N	f
771	Massey Ferguson 235	Massey Ferguson	235	1975	42	\N	1737	19	4x2	Diagonal 12.4-28	315	1247	\N	\N	9.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td756.webp	f	\N	f
2332	Kubota B6100HST	Kubota	B6100HST	1977	14	\N	573	5.1	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7560.webp	f	\N	f
2333	Massey Ferguson 690T	Massey Ferguson	690T	1983	90	\N	3637	33	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7561.webp	t	\N	f
772	John Deere 4044M	John Deere	4044M	2004	42.5	\N	1710	12.3	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7568.webp	f	\N	f
782	Massey Ferguson 243	Massey Ferguson	243	1999	52	\N	2288	19.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	11	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td759.webp	f	\N	f
2841	CaseIH Magnum 200	CaseIH	magnum 200	2014	200	\N	9391	83.1	4x4	Radial 480/80R46	480	1936	\N	\N	36.7	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7590.webp	t	\N	f
2842	CaseIH Magnum 220	CaseIH	magnum 220	2014	220	\N	9865	88.9	4x4	Radial 480/80R46	480	1936	\N	\N	40.1	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7591.webp	t	\N	f
2327	New Holland Workmaster 40	New Holland	Workmaster 40	2013	38	\N	1315	12.3	4x4	Diagonal 13 - 20	330	1069	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7504.webp	f	\N	f
3601	Fiat 455C	Fiat	455C	1970	47.3	\N	2315	17.4	track	Diagonal 70 - 19	1778	3505	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7519.webp	f	\N	f
783	John Deere 7020	John Deere	7020	1971	146.17	\N	8389	83.3	4x4	Diagonal 18.4-34	467	1658	\N	\N	38.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td76.webp	t	\N	f
539	John Deere 730 (1961-1971)	John Deere	730	1961	59	\N	3079	21.6	4x2	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6853.webp	f	\N	f
2843	CaseIH Magnum 240	CaseIH	magnum 240	2014	240	\N	10117	99.1	4x4	Radial 480/80R46	480	1936	\N	\N	45.8	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7592.webp	t	\N	f
2844	CaseIH Puma 150	CaseIH	Puma 150	2014	150	\N	6305	63.3	4x4	Radial 460/85R42	460	1849	\N	\N	29.5	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7593.webp	t	\N	f
1725	CaseIH Puma 165 (2014-2025)	CaseIH	Puma 165	2014	165	\N	6305	64.9	4x4	Radial 460/85R42	460	1849	\N	\N	31.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7594.webp	t	\N	f
2845	CaseIH Puma 220	CaseIH	Puma 220	2014	220	\N	7212	79.1	4x4	Radial 520/85R42	520	1951	\N	\N	42.4	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7597.webp	t	\N	f
2846	CaseIH Puma 240	CaseIH	Puma 240	2014	240	\N	7620	80.4	4x4	Radial 520/85R42	520	1951	\N	\N	47.3	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7598.webp	t	\N	f
2847	CaseIH Farmall 75N	CaseIH	Farmall 75N	2009	76	\N	2419	22.7	4x4	Radial 380/85R28	380	1357	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7600.webp	t	\N	f
2848	CaseIH Farmall 95N	CaseIH	Farmall 95N	2009	95	\N	2639	30.1	4x4	Radial 380/85R28	380	1357	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7601.webp	t	\N	f
2849	CaseIH Farmall 105N	CaseIH	Farmall 105N	2014	106	\N	2639	33.8	4x4	Radial 380/85R28	380	1357	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7602.webp	t	\N	f
785	Massey Ferguson 250	Massey Ferguson	250	1983	40	\N	2079	19.1	4x2	Diagonal 13.6-28	345	1298	\N	\N	10.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td761.webp	f	\N	f
332	Massey Ferguson 253 (1988-1998)	Massey Ferguson	253	1988	57	\N	2147	17.6	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td762.webp	t	\N	f
786	Massey Ferguson 254	Landini	ferguson 254	1982	50	\N	2487	23.5	4x4	Diagonal 13.6-28	345	1298	\N	\N	10.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td763.webp	f	\N	f
787	Massey Ferguson 255	Massey Ferguson	255	1975	50	\N	2540	23.4	4x2	Diagonal 16.9-24	429	1339	\N	\N	12.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td764.webp	f	\N	f
788	Massey Ferguson 261	Ursus	ferguson 261	1992	60	\N	2440	19.4	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td765.webp	f	\N	f
2358	Kubota M100GX	Kubota	M100GX	2000	100	\N	4095	31.6	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7652.webp	t	\N	f
2850	CaseIH Farmall 105V	CaseIH	Farmall 105V	2014	106	\N	2712	33.8	4x4	Diagonal 14 - 20	356	1113	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7603.webp	t	\N	f
2362	Massey Ferguson 6614	Massey Ferguson	ferguson 6614	2014	130	\N	5670	36.7	4x2	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7656.webp	t	\N	f
2363	Massey Ferguson 6615	Massey Ferguson	ferguson 6615	2014	135	\N	5670	40.4	4x2	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7657.webp	t	\N	f
2343	New Holland T6.140	New Holland	T6.140	2012	110	\N	4890	43.2	4x4	Diagonal 12 - 20	305	1026	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7626.webp	t	\N	f
2344	New Holland T6.150	New Holland	T6.150	2012	121	\N	4890	46.4	4x4	Diagonal 12 - 20	305	1026	\N	\N	26.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7627.webp	t	\N	f
2345	New Holland T6.155	New Holland	T6.155	2012	116	\N	5010	47.4	4x4	Diagonal 12 - 20	305	1026	\N	\N	23.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7628.webp	t	\N	f
2346	New Holland T6.160	New Holland	T6.160	2012	131	\N	4890	48.9	4x4	Diagonal 12 - 20	305	1026	\N	\N	25.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7629.webp	t	\N	f
2347	New Holland T6.165	New Holland	T6.165	2012	125	\N	5010	51.3	4x4	Diagonal 12 - 20	305	1026	\N	\N	24.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7630.webp	t	\N	f
2348	New Holland T6.175	New Holland	T6.175	2012	140	\N	5010	50.6	4x4	Diagonal 12 - 20	305	1026	\N	\N	28.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7631.webp	t	\N	f
2245	New Holland 7630 S100	New Holland	7630 S100	2002	102.9	\N	3630	31.9	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7079.webp	t	\N	f
2246	New Holland 8030 S100	New Holland	8030 S100	2002	121.4	\N	3840	37.5	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7080.webp	f	\N	f
2364	Massey Ferguson 6616	Massey Ferguson	ferguson 6616	2014	150	\N	5670	44	4x2	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7658.webp	t	\N	f
1851	CaseIH Magnum 335 (2007-2011)	CaseIH	Magnum 335	2007	335	\N	9566	122.9	4x4	Radial 710/70R42	710	2061	\N	\N	70	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7732.webp	t	\N	f
2851	CaseIH Magnum 250 (2014-2025)	CaseIH	Magnum 250	2014	250	\N	12972	92.2	4x4	Radial 480/80R50	480	2038	\N	\N	51.1	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7738.webp	t	\N	f
2852	CaseIH Magnum 280 (2014-2025)	CaseIH	Magnum 280	2014	280	\N	12972	116.2	4x4	Radial 480/80R50	480	2038	\N	\N	57.2	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7739.webp	t	\N	f
334	Massey Ferguson 283 (1985-1999)	Massey Ferguson	283	1985	89	\N	2463	24.6	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td774.webp	f	\N	f
2853	CaseIH Magnum 310 (2014-2025)	CaseIH	Magnum 310	2014	310	\N	13063	107.2	4x4	Radial 480/80R50	480	2038	\N	\N	60.6	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7740.webp	t	\N	f
2857	CaseIH Magnum 380	CaseIH	magnum 380	2014	380	\N	15800	129.1	4x4	Radial 480/80R50	480	2038	\N	\N	73.8	\N	available	2026-09-30 16:51:28.845746	https://media.sandhills.com/img.axd?id=8046330059&wid=4326205933&rwl=False&p=&ext=&w=614&h=460&t=&lp=&c=True&wt=False&sz=Max&rt=0&checksum=TWOKv2gmK16bV5xB6MjzDJylQWdOV9SLQQ%2B39zAM1as%3D	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Produtos/Tratores/Linha-Magnum/Magnum%20AFS/CIH_Folleto-Magnum-AFS-Connect-Espanol.pdf#page=13	t
796	Massey Ferguson 285	Massey Ferguson	285	1974	81	\N	3470	39.3	4x4	Diagonal 16.9-38	429	1695	\N	\N	20.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td775.webp	f	\N	f
17	Massey Ferguson 290	Massey Ferguson	290	1983	80	\N	2990	34	4x4	Diagonal 16.9-28	429	1441	\N	\N	15.9	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td776.webp	f	\N	f
797	John Deere 5085E	John Deere	5085E	2013	85	\N	3200	25.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7760.webp	t	\N	f
798	John Deere 5100E	John Deere	5100E	2013	100	\N	3200	32.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	21.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7761.webp	t	\N	f
799	Massey Ferguson 294	Landini	ferguson 294	1982	67	\N	3048	25.2	4x4	Diagonal 18.4x30	467	1557	\N	\N	14.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td777.webp	f	\N	f
2374	Kubota L1802	Kubota	L1802	1978	17.8	\N	879	6.5	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7773.webp	f	\N	f
2375	Kubota L2002	Kubota	L2002	1978	19.7	\N	899	7.2	4x4	Diagonal 9.2-22	234	956	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7774.webp	f	\N	f
2376	Kubota L2202	Kubota	L2202	1978	21.7	\N	919	8	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7775.webp	f	\N	f
2377	Kubota L2402	Kubota	L2402	1978	23.7	\N	1000	8.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7776.webp	f	\N	f
800	Massey Ferguson 298	Massey Ferguson	298	1983	78	\N	3165	38.7	4x2	Diagonal 18.4-34	467	1658	\N	\N	19.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td778.webp	f	\N	f
266	John Deere 7520 (1972-1975)	John Deere	7520	1972	175	\N	7615	100.2	4x4	Diagonal 23.1-30	587	1759	\N	\N	43.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td78.webp	t	\N	f
801	Massey Ferguson 354S	Massey Ferguson	354S	1994	42	\N	2280	15.4	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td781.webp	f	\N	f
2858	CaseIH 3294	CaseIH	3294	1985	197	\N	7711	72.2	4x4	Diagonal 23.1x34	587	1861	\N	\N	40.1	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7825.webp	t	\N	f
2380	Massey Ferguson 3635	Massey Ferguson	3635	1990	135	\N	5670	49.5	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7827.webp	t	\N	f
2381	Massey Ferguson 3645	Massey Ferguson	3645	1990	145	\N	5670	53.2	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7828.webp	t	\N	f
2382	Massey Ferguson 3655	Massey Ferguson	3655	1990	155	\N	5806	56.9	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7829.webp	t	\N	f
2378	Kubota RV Ridevator	Kubota	RV Ridevator	1965	9	\N	521	3.2	4x2	Diagonal 65 - 19	1651	3289	\N	\N	3.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7782.webp	f	\N	f
809	John Deere 9570R	John Deere	9570R	2015	570	\N	19754	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7886.webp	f	\N	f
810	John Deere 9620R	John Deere	9620R	2015	620	\N	19754	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7887.webp	f	\N	f
2190	CaseIH 795	CaseIH	795	1991	77	\N	3392	25.3	4x4	Diagonal 16.9x34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6863.webp	f	\N	f
2191	CaseIH 785	CaseIH	785	1985	77	\N	3392	25.3	4x4	Diagonal 16.9x34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6864.webp	f	\N	f
2193	Massey Ferguson 6110	Massey Ferguson	ferguson 6110	1995	71	\N	4000	26	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6891.webp	f	\N	f
2194	Massey Ferguson 6120	Massey Ferguson	ferguson 6120	1995	80	\N	4014	29.4	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6892.webp	f	\N	f
2195	Massey Ferguson 6130	Massey Ferguson	ferguson 6130	1995	85	\N	4132	31.2	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6893.webp	t	\N	f
2196	Massey Ferguson 6140	Massey Ferguson	ferguson 6140	1995	90	\N	4150	33	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6894.webp	t	\N	f
2197	Kubota B5000	Kubota	B5000	1973	9	\N	408	2.9	4x4	Diagonal 7-14	178	658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6899.webp	f	\N	f
2383	Massey Ferguson 8110	Massey Ferguson	8110	1995	135	\N	5783	49.5	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7830.webp	t	\N	f
2384	Massey Ferguson 8130	Massey Ferguson	8130	1995	155	\N	6041	56.9	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7832.webp	t	\N	f
2859	CaseIH 743 XL	CaseIH	743 XL	1985	67	\N	3759	24.6	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7833.webp	f	\N	f
2861	CaseIH 844 XL	CaseIH	844 XL	1985	80	\N	3969	29.4	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7835.webp	f	\N	f
2862	CaseIH 856 XL	CaseIH	856 XL	1985	85	\N	4119	31.2	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7836.webp	t	\N	f
2863	CaseIH 956 XL	CaseIH	956 XL	1985	95	\N	4672	34.9	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7837.webp	f	\N	f
2864	CaseIH 1056 XL	CaseIH	1056 XL	1985	105	\N	4749	38.5	4x4	Radial 18.9R38	480	1781	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7838.webp	f	\N	f
2865	CaseIH 1255 XL	CaseIH	1255 XL	1985	125	\N	5679	45.9	4x4	Radial 18.9R38	480	1781	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7839.webp	t	\N	f
802	Massey Ferguson 362	Massey Ferguson	362	1988	61	\N	2703	20.2	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td784.webp	f	\N	f
2866	CaseIH 1455 XL	CaseIH	1455 XL	1985	145	\N	5215	53.2	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7840.webp	t	\N	f
803	John Deere 6100B	John Deere	6100B	2000	106	\N	3700	33	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7859.webp	t	\N	f
670	John Deere 7260R	John Deere	7260R	2011	260	\N	16000	106.8	4x4	Diagonal 11 - 20	279	983	\N	\N	51.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6857.webp	t	\N	f
671	John Deere 7280R	John Deere	7280R	2011	280	\N	16000	105.2	4x4	Diagonal 11 - 20	279	983	\N	\N	56.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6858.webp	t	\N	f
2192	Kubota L2000	Kubota	L2000	1971	19.7	\N	795	7.2	4x4	Diagonal 8-22	203	904	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6882.webp	f	\N	f
2860	CaseIH 745 XL	CaseIH	745 XL	1985	72	\N	3929	26.4	4x4	Diagonal 85 - 19	2159	4153	\N	\N	\N	\N	available	2026-09-30 16:51:28.845746	/uploads/tractors/td7834.webp	f	\N	f
805	John Deere 9370R	John Deere	9370R	2015	370	\N	17781	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7882.webp	f	\N	f
807	John Deere 9470R	John Deere	9470R	2015	470	\N	19191	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7884.webp	f	\N	f
808	John Deere 9520R	John Deere	9520R	2015	520	\N	19754	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7885.webp	f	\N	f
814	John Deere 4030	John Deere	4030	1973	80	\N	3329	33.4	4x2	Diagonal 15.5-38	394	1634	\N	\N	21.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td79.webp	f	\N	f
2387	Kubota MX4800	Kubota	MX4800	2014	49.3	\N	1683	14.9	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7901.webp	f	\N	f
821	Massey Ferguson 390T	Massey Ferguson	390T	1989	92	\N	3153	30.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td801.webp	t	\N	f
494	John Deere 820 (1968-1973)	John Deere	820	1968	32	\N	1814	11.4	4x2	Diagonal 12.2-28	310	1238	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td69.webp	f	\N	f
2198	Kubota B6001	Kubota	B6001	1976	14	\N	476	4.2	4x2	Diagonal 7-14	178	658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6900.webp	f	\N	f
2199	Kubota B1200	Kubota	B1200	1979	16	\N	480	4.4	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6901.webp	f	\N	f
2200	Kubota B1400	Kubota	B1400	1979	19	\N	498	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6902.webp	f	\N	f
2201	Kubota B1500	Kubota	B1500	1980	19	\N	544	5.5	4x2	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6903.webp	f	\N	f
2202	Kubota B1600	Kubota	B1600	1979	20	\N	639	5.9	4x2	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6904.webp	f	\N	f
2203	Kubota B1402	Kubota	B1402	1981	13.8	\N	498	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6905.webp	f	\N	f
2204	Kubota B1702	Kubota	B1702	1981	16.8	\N	664	6.2	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6907.webp	f	\N	f
2205	Kubota B1902	Kubota	B1902	1981	18.7	\N	754	6.9	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6908.webp	f	\N	f
2388	Kubota MX5200	Kubota	MX5200	2014	54.7	\N	1685	16.8	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7902.webp	t	\N	f
815	Massey Ferguson 374S	Massey Ferguson	374S	1994	57	\N	2500	20.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td791.webp	f	\N	f
641	John Deere 5090M (2018-2022)	John Deere	5090M	2018	89.2	\N	3975	30.7	4x4	Radial 460/85R30	460	1544	\N	\N	17.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td795.webp	t	https://digitalcommons.unl.edu/tractormuseumlit/1243/	f
819	Massey Ferguson 384S	Massey Ferguson	384S	1994	65	\N	2500	23.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td798.webp	f	\N	f
820	John Deere 4230	John Deere	4230	1973	100	\N	3674	49.6	4x4	Diagonal 23.1-26	587	1658	\N	\N	26.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td80.webp	f	\N	f
822	Massey Ferguson 393 (1992-1997)	Massey Ferguson	393	1992	95	\N	3168	33.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td802.webp	t	\N	f
2389	New Holland TZ21D	New Holland	TZ21D	2008	21	\N	662	7.7	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8057.webp	f	\N	f
2390	New Holland TZ24D	New Holland	TZ24D	2008	24	\N	662	8.8	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8058.webp	f	\N	f
823	Massey Ferguson 394S	Massey Ferguson	394S	1994	73	\N	2550	26.8	4x4	Diagonal 16.9-24	429	1339	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td806.webp	f	\N	f
3613	Zetor 14145	Zetor	14145	1987	140	\N	4672	51.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8061.webp	t	\N	f
2391	Massey Ferguson 3625F	Massey Ferguson	3625F	2011	69	\N	2760	25.3	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8062.webp	f	\N	f
2392	Massey Ferguson 3635F	Massey Ferguson	3635F	2011	80	\N	2760	29.4	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8063.webp	f	\N	f
2393	Massey Ferguson 3640F	Massey Ferguson	3640F	2011	84	\N	2760	30.8	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8064.webp	f	\N	f
2394	Massey Ferguson 3650F	Massey Ferguson	3650F	2011	94	\N	2760	34.5	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8065.webp	f	\N	f
2395	Massey Ferguson 3660F	Massey Ferguson	3660F	2011	102	\N	2760	37.4	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8066.webp	f	\N	f
2396	Massey Ferguson 3630A	Massey Ferguson	3630A	2000	76	\N	2830	27.9	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8067.webp	f	\N	f
2397	Massey Ferguson 3640A	Massey Ferguson	3640A	2000	84	\N	2830	30.8	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8068.webp	f	\N	f
2398	Massey Ferguson 3650A	Massey Ferguson	3650A	2000	92	\N	2830	33.8	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8069.webp	f	\N	f
824	Massey Ferguson 396	Massey Ferguson	396	1992	104	\N	3488	33.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td807.webp	f	\N	f
836	John Deere 6110R	John Deere	6110R	2015	110	\N	8949	31.6	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8102.webp	t	\N	f
2400	Kubota M7-131	Kubota	M7 131	2015	128	\N	6847	69.4	4x4	Radial 18.4R38	467	1760	\N	\N	31.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8082.webp	f	\N	f
2401	Kubota M7-151	Kubota	M7 151	2015	148	\N	6847	70.5	4x4	Radial 18.4R38	467	1760	\N	\N	33.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8083.webp	f	\N	f
2402	Kubota M7-171	Kubota	M7 171	2015	168	\N	6847	76.2	4x4	Radial 18.4R38	467	1760	\N	\N	35.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8084.webp	f	\N	f
2403	Kubota L2501	Kubota	L2501	2014	24.8	\N	1179	7.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8085.webp	f	\N	f
18	Kubota L3301	Kubota	L3301	2014	33	\N	1240	12.1	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td8086.webp	f	\N	f
2404	Kubota L3901	Kubota	L3901	2014	37.5	\N	1255	11.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8087.webp	f	\N	f
2405	Kubota L4701	Kubota	L4701	2014	47.3	\N	1495	14.4	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8088.webp	f	\N	f
825	John Deere 3110	Renault	deere 3110	1998	55	\N	3111	20.2	4x4	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8091.webp	f	\N	f
826	John Deere 3210	Renault	deere 3210	1998	65	\N	3329	23.8	4x4	Radial 13.6R36	345	1502	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8092.webp	f	\N	f
827	John Deere 3310	Renault	deere 3310	1998	75	\N	3424	27.5	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8093.webp	f	\N	f
828	John Deere 3410	Renault	deere 3410	1998	85	\N	3470	31.2	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8094.webp	t	\N	f
829	John Deere 5300	Carraro	deere 5300	1996	55	\N	2590	20.2	4x4	Radial 14.9R30	378	1405	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8095.webp	f	\N	f
830	John Deere 5400	Carraro	deere 5400	1996	70	\N	2608	25.7	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8096.webp	t	\N	f
831	John Deere 5500	Carraro	deere 5500	1996	80	\N	2903	29.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8097.webp	t	\N	f
832	John Deere 5310	Carraro	deere 5310	2000	53	\N	3084	19.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8098.webp	f	\N	f
833	John Deere 5410	Carraro	deere 5410	2000	72	\N	3084	26.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8099.webp	t	\N	f
834	John Deere 4430	John Deere	4430	1973	125	\N	4414	53.5	4x2	Diagonal 18.4-38	467	1760	\N	\N	30.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td81.webp	t	\N	f
835	John Deere 5510	Carraro	deere 5510	2000	80	\N	3197	29.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8100.webp	t	\N	f
793	Massey Ferguson 275 (1977-1987)	Massey Ferguson	275	1977	70	\N	2522	25.7	4x2	Diagonal 18.4x30	467	1557	\N	\N	17.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8101.webp	f	\N	f
837	John Deere 6120R	John Deere	6120R	2015	120	\N	9950	62.4	4x4	Radial 16.9R30	429	1492	\N	\N	25	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8103.webp	t	\N	f
718	John Deere 6130R (2015-2021)	John Deere	6130R	2015	130	\N	5469	37.1	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8104.webp	t	\N	f
838	Massey Ferguson 670	Massey Ferguson	670	1983	56	\N	3955	35.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	13.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td812.webp	f	\N	f
2406	Massey Ferguson 1325	Massey Ferguson	1325	2002	27	\N	1005	9.9	4x4	Diagonal 250/80-18	250	857	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8126.webp	f	\N	f
2407	Massey Ferguson 1335	Massey Ferguson	1335	2002	35	\N	1139	12.8	4x4	Radial 320/70R20	320	956	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8127.webp	f	\N	f
2408	Massey Ferguson 1345	Massey Ferguson	1345	2002	42	\N	1010	15.4	4x4	Radial 360/70R24	360	1114	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8128.webp	t	\N	f
2409	New Holland TL70A	New Holland	TL70A	2004	72	\N	3850	26.4	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8129.webp	f	\N	f
839	Massey Ferguson 690	Massey Ferguson	690	1983	80	\N	3637	34	4x4	Diagonal 18.4-34	467	1658	\N	\N	17	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td813.webp	f	\N	f
2063	New Holland TL80A (2004-2008)	New Holland	TL80A	2004	82	\N	4050	30.1	4x4	Radial 16.9R34	429	1593	\N	\N	18.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8130.webp	f	\N	f
2064	New Holland TL90A (2004-2008)	New Holland	TL90A	2004	91	\N	4250	33.4	4x4	Radial 480/70R34	480	1536	\N	\N	20.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8131.webp	t	\N	f
2065	New Holland TL100A (2004-2008)	New Holland	TL100A	2004	100	\N	4250	36.7	4x4	Radial 480/70R34	480	1536	\N	\N	21.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8132.webp	t	\N	f
2410	New Holland Boomer 24	LS	holland boomer 24	2014	24	\N	830	6.1	4x4	Diagonal 12-16.5	305	937	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8133.webp	f	\N	f
2411	New Holland Boomer 33	New Holland	holland boomer 33	2014	32.2	\N	1271	9.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8134.webp	t	\N	f
2412	New Holland Boomer 37	New Holland	Boomer 37	2014	36.2	\N	1271	11.4	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8135.webp	t	\N	f
2413	New Holland Boomer 41	New Holland	Boomer 41	2014	40.2	\N	1553	11.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8136.webp	f	\N	f
2414	New Holland Boomer 47	New Holland	Boomer 47	2014	45.6	\N	1553	13.7	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8137.webp	f	\N	f
840	Massey Ferguson 698	Massey Ferguson	698	1983	78	\N	4508	38.7	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td814.webp	f	\N	f
692	John Deere 7205J	John Deere	7205J	2000	205	\N	8101	63.8	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7104.webp	t	\N	f
693	John Deere 7225J	John Deere	7225J	2000	225	\N	8101	70.1	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7105.webp	t	\N	f
694	John Deere 7715	John Deere	7715	2007	182	\N	8101	55.4	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7106.webp	f	\N	f
739	John Deere 7250R (2000-2024)	John Deere	7250R	2000	250	\N	10816	75.2	4x4	Radial 320/90R54	320	1948	\N	\N	50.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8153.webp	t	\N	f
740	John Deere 7270R (2000-2024)	John Deere	7270R	2000	270	\N	10816	82.2	4x4	Radial 320/90R54	320	1948	\N	\N	54.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8154.webp	t	\N	f
741	John Deere 7290R (2000-2024)	John Deere	7290R	2000	290	\N	10816	88.8	4x4	Radial 320/90R54	320	1948	\N	\N	55.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8155.webp	t	\N	f
842	John Deere 7310R (2000-2024)	John Deere	7310R	2000	310	\N	11326	95.4	4x4	Radial 320/90R54	320	1948	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8156.webp	t	\N	f
2425	Kubota L1-18	Kubota	L1 18	1983	17.8	\N	975	6.5	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8157.webp	f	\N	f
2426	Kubota L1-20	Kubota	L1 20	1983	19.7	\N	980	7.2	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8158.webp	f	\N	f
2427	Kubota L1-22	Kubota	L1 22	1983	21.7	\N	1010	8	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8159.webp	f	\N	f
843	Massey Ferguson 1010	Toyosha	ferguson 1010	1982	16	\N	644	4.8	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td816.webp	f	\N	f
2428	Kubota L1-24	Kubota	L1 24	1983	23.7	\N	1070	8.7	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8160.webp	f	\N	f
2429	Kubota L1-26	Kubota	L1 26	1983	25.6	\N	1149	9.4	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8161.webp	f	\N	f
2430	Kubota L1-28	Kubota	L1 28	1983	27.6	\N	1190	10.1	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8162.webp	f	\N	f
2431	Kubota L1-195	Kubota	L1 195	1988	18.7	\N	975	6.9	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8164.webp	f	\N	f
2432	Kubota L1-215	Kubota	L1 215	1986	20.7	\N	980	7.6	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8166.webp	f	\N	f
2433	Kubota L1-235	Kubota	L1 235	1986	22.7	\N	1010	8.3	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8167.webp	f	\N	f
2434	Kubota L1-255	Kubota	L1 255	1988	24.7	\N	1070	8.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8169.webp	f	\N	f
844	Massey Ferguson 1020	Toyosha	ferguson 1020	1983	21	\N	1235	6.2	4x4	Diagonal 8.3x24	211	968	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td817.webp	f	\N	f
845	Massey Ferguson 1030	Toyosha	ferguson 1030	1984	26	\N	1087	10.1	4x4	Diagonal 13.6x16	345	994	\N	\N	6.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td818.webp	f	\N	f
2435	Massey Ferguson 250X	Massey Ferguson	250X	2000	50.3	\N	2893	18.5	4x4	Diagonal 14.9x24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8183.webp	f	\N	f
847	Massey Ferguson 1035	Toyosha	ferguson 1035	1986	31	\N	1229	9.5	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td819.webp	f	\N	f
2867	CaseIH 485XL	CaseIH	485XL	1985	52	\N	2549	15	4x2	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8190.webp	f	\N	f
2868	CaseIH 585XL	CaseIH	585XL	1985	60	\N	3265	19.6	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8191.webp	f	\N	f
2870	CaseIH 785XL	CaseIH	785XL	1985	77	\N	3265	28.3	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8193.webp	f	\N	f
2871	CaseIH 885XL	CaseIH	885XL	1985	83	\N	3560	30.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8194.webp	f	\N	f
2872	CaseIH PJ55	CaseIH	PJ55	2001	55	\N	2515	20.2	4x4	Radial 380/70R28	380	1243	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8199.webp	f	\N	f
2436	Massey Ferguson 294C	Massey Ferguson	294C	1982	74	\N	3915	27.1	track	Diagonal 82 - 19	2083	4023	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8184.webp	f	\N	f
846	John Deere 1020 VU	John Deere	1020 VU	1967	44	\N	1710	16.1	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8188.webp	f	\N	f
695	John Deere 7815	John Deere	7815	2005	202	\N	8101	61.3	4x4	Diagonal 20.8-42	528	1965	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7107.webp	f	\N	f
696	John Deere 6110J	John Deere	6110J	2000	110	\N	4708	34.5	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7108.webp	t	\N	f
697	John Deere 6125J	John Deere	6125J	2000	125	\N	4921	38.9	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7109.webp	t	\N	f
698	John Deere 6145J	John Deere	6145J	2000	145	\N	5651	45.1	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7110.webp	t	\N	f
699	John Deere 6165J	John Deere	6165J	2000	165	\N	6890	52.5	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7111.webp	t	\N	f
700	John Deere 6180J	John Deere	6180J	2000	180	\N	7194	55.8	4x4	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7112.webp	t	\N	f
701	John Deere 6110E	John Deere	6110E	2000	110	\N	3959	34.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7113.webp	t	\N	f
702	John Deere 6125E	John Deere	6125E	2000	125	\N	4590	38.9	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7114.webp	t	\N	f
703	John Deere 5605	John Deere	5605	2000	75	\N	2899	23.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7115.webp	f	\N	f
704	John Deere 5705	John Deere	5705	2000	85	\N	2899	26.4	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7116.webp	t	\N	f
359	John Deere 6405 (1998-2005)	John Deere	6405	1998	106	\N	4250	33	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7117.webp	t	\N	f
577	John Deere 6605 (1998-2005)	John Deere	6605	1998	121	\N	4558	37.8	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7118.webp	t	\N	f
705	John Deere 7505	John Deere	7505	1998	140	\N	5470	43.7	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7119.webp	t	\N	f
255	John Deere 6415 (2005-2010)	John Deere	6415	2005	108	\N	6001	33	4x4	Diagonal 23.1-30	587	1759	\N	\N	22.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7120.webp	t	\N	f
256	John Deere 6615 (2005-2010)	John Deere	6615	2005	120.3	\N	6999	37.8	4x4	Diagonal 23.1-30	587	1759	\N	\N	24.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7121.webp	t	\N	f
848	John Deere 4630	John Deere	4630	1973	150	\N	7371	64.4	4x2	Diagonal 18.4-38	467	1760	\N	\N	36.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td82.webp	t	\N	f
849	Massey Ferguson 1040	Toyosha	ferguson 1040	1984	32	\N	1519	9.9	4x4	Diagonal 13.6x24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td820.webp	f	\N	f
2873	CaseIH PJ65	CaseIH	PJ65	2001	65	\N	2575	23.8	4x4	Radial 380/70R28	380	1243	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8200.webp	f	\N	f
2874	CaseIH PJ75	CaseIH	PJ75	2001	75	\N	2575	27.5	4x4	Radial 380/70R28	380	1243	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8201.webp	f	\N	f
850	Massey Ferguson 1045	Toyosha	ferguson 1045	1986	35	\N	1601	11	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td821.webp	f	\N	f
712	John Deere 6105R (2012-2016)	John Deere	6105R	2012	105	\N	5440	38.5	4x4	Diagonal 12 - 20	305	1026	\N	\N	23.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7153.webp	t	\N	f
713	John Deere 6115R (2012-2016)	John Deere	6115R	2012	115	\N	5455	42.2	4x4	Diagonal 12 - 20	305	1026	\N	\N	25	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7154.webp	t	\N	f
714	John Deere 6125R (2012-2016)	John Deere	6125R	2012	125	\N	5470	45.9	4x4	Diagonal 12 - 20	305	1026	\N	\N	26.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7155.webp	t	\N	f
856	Massey Ferguson 1125	Iseki	ferguson 1125	1992	25	\N	1194	8.3	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td827.webp	f	\N	f
851	Massey Ferguson 1080	Massey Ferguson	1080	1969	80	\N	3515	39.8	4x4	Diagonal 23.1x30	587	1759	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td822.webp	f	\N	f
852	Massey Ferguson 1085	Massey Ferguson	1085	1973	81	\N	3810	46.1	4x2	Diagonal 18.4-34	467	1658	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td823.webp	f	\N	f
2438	Kubota MX5800	Kubota	MX5800	2015	61.4	\N	1693	18.4	4x4	Diagonal 14.9-26	378	1304	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8234.webp	t	\N	f
2439	Kubota M5660SU	Kubota	M5660SU	2000	57.9	\N	1989	18.3	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8235.webp	t	\N	f
853	Massey Ferguson 1100	Massey Ferguson	1100	1964	94	\N	4082	49.5	4x2	Diagonal 15.5-38	394	1634	\N	\N	23.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td824.webp	f	\N	f
2440	Massey Ferguson 7719	Massey Ferguson	ferguson 7719	2015	170	\N	6999	71.6	4x4	Radial 480/80R42	480	1835	\N	\N	37.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8240.webp	t	\N	f
2441	Massey Ferguson 7720	Massey Ferguson	ferguson 7720	2015	185	\N	6999	72.5	4x4	Radial 480/80R42	480	1835	\N	\N	38.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8241.webp	t	\N	f
2442	Massey Ferguson 7722	Massey Ferguson	ferguson 7722	2015	200	\N	7500	69.1	4x4	Radial 480/80R42	480	1835	\N	\N	41.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8242.webp	t	\N	f
2443	Massey Ferguson 7724	Massey Ferguson	ferguson 7724	2015	220	\N	7500	80.6	4x4	Radial 480/80R46	480	1936	\N	\N	46.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8243.webp	t	\N	f
2444	Massey Ferguson 7726	Massey Ferguson	ferguson 7726	2015	240	\N	7500	80.5	4x4	Radial 480/80R46	480	1936	\N	\N	48.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8244.webp	t	\N	f
854	Massey Ferguson 1105	Massey Ferguson	1105	1973	111	\N	4876	50.6	4x2	Diagonal 18.4-38	467	1760	\N	\N	28.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td825.webp	t	\N	f
2875	CaseIH Steiger 540	CaseIH	steiger 540	2014	542	\N	21839	216.4	4x4	Radial 710/70R42	710	2061	\N	\N	106.7	\N	available	2026-09-30 16:52:15.039773	https://bane-welker.com/media/catalog/product/p/h/photo0.15875.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
2876	CaseIH Steiger 580	CaseIH	steiger 580	2014	588	\N	21839	242.8	4x4	Radial 710/70R42	710	2061	\N	\N	105.6	\N	available	2026-09-30 16:52:15.039773	https://i.machinio.com/medium/cmm/4006/case-ih-steiger-580-tractor-a0c464d19c2f.axd	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
2877	CaseIH Steiger 620	CaseIH	steiger 620	2014	629	\N	21839	231.7	4x4	Radial 710/70R42	710	2061	\N	\N	106	\N	available	2026-09-30 16:52:15.039773	https://photos.machinefinder.com/33/10609233/68614692_huge_91275.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Espanhol/Tractores/CIH-0029-21A_Folheto-Steiger-EObx.pdf#page=16	t
2907	CaseIH 2120	Carraro	2120	1988	40	\N	1860	14.7	4x4	Radial 13.6R28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8256.webp	f	\N	f
855	Massey Ferguson 1120	Iseki	ferguson 1120	1993	16.6	\N	576	5	4x4	Diagonal 29.00x12.00-15	305	737	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td826.webp	f	\N	f
2454	Kubota MZ505	Kubota	MZ505	2010	49.3	\N	2370	18.1	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8299.webp	f	\N	f
61	John Deere 830 (1973-1975)	John Deere	830	1973	35	\N	1984	18.9	4x2	Diagonal 13.6-28	345	1298	\N	\N	9.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td83.webp	f	\N	f
859	Massey Ferguson 1140	Iseki	ferguson 1140	1991	30	\N	1224	9.6	4x4	Diagonal 12.4x24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td830.webp	f	\N	f
2455	Kubota MZ555	Kubota	MZ555	2010	54.2	\N	2409	19.9	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8300.webp	f	\N	f
2456	Kubota MZ605	Kubota	MZ605	2010	59.2	\N	2409	21.7	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8301.webp	f	\N	f
2457	Kubota MZ655	Kubota	MZ655	2010	64.1	\N	2550	23.5	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8302.webp	t	\N	f
2206	Kubota B1-14	Kubota	B1 14	1985	14	\N	550	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6909.webp	f	\N	f
2207	Kubota B1-15	Kubota	B1 15	1985	16	\N	570	5.9	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6910.webp	f	\N	f
2208	Kubota B1-16	Kubota	B1 16	1985	16.5	\N	689	6.1	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6911.webp	f	\N	f
2209	Kubota B1-17	Kubota	B1 17	1985	17	\N	694	6.2	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6912.webp	f	\N	f
2210	CaseIH Magnum 370	CaseIH	Magnum 370	2012	367	\N	14147	111.9	4x4	Radial 480/80R50	480	2038	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6972.webp	t	\N	f
2215	New Holland T1530	New Holland	T1530	2011	45	\N	1501	13.9	4x4	Diagonal 13.6x16	345	994	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6983.webp	f	\N	f
672	John Deere 6530	John Deere	6530	2006	120	\N	5166	37.4	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6991.webp	t	\N	f
673	John Deere 6630	John Deere	6630	2006	130	\N	5166	41.5	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6992.webp	t	\N	f
674	John Deere 6830	John Deere	6830	2006	140	\N	5633	44	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6993.webp	t	\N	f
675	John Deere 6930	John Deere	6930	2006	155	\N	5633	49.5	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6994.webp	t	\N	f
676	John Deere 6534	John Deere	6534	2009	125	\N	5166	45.9	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6995.webp	t	\N	f
677	John Deere 6530 Premium	John Deere	6530 Premium	2006	120	\N	5080	37.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td6999.webp	t	\N	f
678	John Deere 1520	John Deere	1520	1968	47.86	\N	2036	22.6	4x2	Diagonal 14.9-28	378	1355	\N	\N	11.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td70.webp	f	\N	f
679	John Deere 6630 Premium	John Deere	6630 Premium	2006	130	\N	5230	41.1	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7000.webp	t	\N	f
680	John Deere 6830 Premium	John Deere	6830 Premium	2006	140	\N	5579	44.4	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7001.webp	t	\N	f
2211	CaseIH Farmall 30B	CaseIH	Farmall 30B	2012	28	\N	1415	8.4	4x4	Diagonal 12 - 20	305	1026	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6979.webp	f	\N	f
2212	CaseIH Farmall 35B	CaseIH	Farmall 35B	2012	38	\N	1451	11.4	4x4	Diagonal 12 - 20	305	1026	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6980.webp	f	\N	f
2213	CaseIH Farmall 40B	CaseIH	Farmall 40B	2012	41	\N	1689	12.5	4x4	Diagonal 12 - 20	305	1026	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6981.webp	f	\N	f
2214	CaseIH Farmall 50B	CaseIH	Farmall 50B	2012	47	\N	1723	14.3	4x4	Diagonal 12 - 20	305	1026	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6982.webp	f	\N	f
2216	Massey Ferguson 35X	Massey Ferguson	35X	1962	44.5	\N	1497	16.3	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td6984.webp	f	\N	f
682	John Deere 6534 Premium	John Deere	6534 Premium	2009	125	\N	4948	45.9	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7003.webp	t	\N	f
868	Massey Ferguson 1180	Massey Ferguson	1180	1992	52	\N	1974	16.9	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td836.webp	f	\N	f
869	Massey Ferguson 1190	Massey Ferguson	1190	1992	60	\N	1984	19.4	4x4	Diagonal 14.9-28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td837.webp	t	\N	f
2219	Massey Ferguson 1078	Massey Ferguson	1078	1971	75	\N	4556	27.5	4x2	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7030.webp	f	\N	f
3542	Belarus 5530	Belarus	5530	2000	36	\N	1528	13.2	4x4	Diagonal 12.4x16	315	942	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7039.webp	f	\N	f
3543	Belarus 5560	Belarus	5560	2000	65	\N	4100	23.8	4x4	Diagonal 15.5x38	394	1634	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7040.webp	f	\N	f
2458	Kubota MZ705	Kubota	MZ705	2010	69	\N	2550	25.3	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8303.webp	t	\N	f
2459	Kubota MZ755	Kubota	MZ755	2010	74	\N	2580	27.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8304.webp	t	\N	f
860	Massey Ferguson 1145	Iseki	ferguson 1145	1991	35	\N	1275	11.4	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td831.webp	t	\N	f
2467	Kubota MR87	Kubota	MR87	2011	85.8	\N	3339	31.5	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8321.webp	t	\N	f
866	Massey Ferguson 1165	Massey Ferguson	1165	1999	44	\N	1941	13.6	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td835.webp	f	\N	f
867	John Deere 5100MH	John Deere	5100MH	2012	100	\N	3764	31.2	4x4	Radial 230/95R40	230	1453	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8351.webp	t	\N	f
872	John Deere 1530	John Deere	1530	1973	46	\N	2177	22.9	4x2	Diagonal 13.6-28	345	1298	\N	\N	12.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td84.webp	f	\N	f
875	John Deere 7525	John Deere	7525	2000	155	\N	5878	49.5	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8405.webp	f	\N	f
3614	Belarus 592 MIG	Pronar	592 mig	2000	70	\N	3800	25.7	4x2	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8407.webp	f	\N	f
3615	Belarus 920 MIG	Pronar	920 mig	2000	90	\N	4010	33	4x2	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8408.webp	f	\N	f
3616	Belarus 952 MIG	Pronar	952 mig	2000	105	\N	4010	38.5	4x2	Radial 480/70R34	480	1536	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8409.webp	t	\N	f
876	Massey Ferguson 1220	Iseki	ferguson 1220	1995	21	\N	750	6.4	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td841.webp	f	\N	f
3618	Belarus 1221 MIG	Pronar	1221 mig	2000	130	\N	5148	47.7	4x2	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8411.webp	t	\N	f
877	Massey Ferguson 1225	Iseki	ferguson 1225	1999	24.3	\N	679	7	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td842.webp	f	\N	f
2469	Massey Ferguson 3095	Massey Ferguson	3095	1990	107	\N	4590	39.3	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8428.webp	f	\N	f
878	Massey Ferguson 1230	Iseki	ferguson 1230	1993	27	\N	860	7.9	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td843.webp	f	\N	f
2217	Massey Ferguson 133	Massey Ferguson	133	1969	37.5	\N	1440	13.8	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7010.webp	f	\N	f
2218	Massey Ferguson 133 Super	Massey Ferguson	133 Super	1975	42	\N	1910	15.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7011.webp	f	\N	f
865	John Deere 5115ML	John Deere	5115ML	2012	115	\N	3606	36.7	4x4	Diagonal 12 - 20	305	1026	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8349.webp	t	\N	f
873	Massey Ferguson 1215	Iseki	ferguson 1215	1996	18	\N	662	5.7	4x4	Diagonal 8.00-18	203	803	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td840.webp	f	\N	f
874	John Deere 7425	John Deere	7425	2000	138	\N	5538	45.1	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8404.webp	f	\N	f
3544	Belarus 5570	Belarus	5570	2000	87	\N	4296	31.9	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7041.webp	f	\N	f
3545	Belarus 5590	Belarus	5590	2000	105	\N	4296	38.5	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7042.webp	t	\N	f
2220	New Holland TL5040	New Holland	TL5040	2007	80	\N	3600	25.7	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7046.webp	t	\N	f
2221	New Holland TL5050	New Holland	TL5050	2007	90	\N	3600	29.4	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7047.webp	t	\N	f
2222	New Holland TL5060	New Holland	TL5060	2007	100	\N	3600	32.1	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7048.webp	t	\N	f
2223	Massey Ferguson 410	Massey Ferguson	410	2004	55	\N	2275	20.2	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7052.webp	t	\N	f
2224	Massey Ferguson 420	Massey Ferguson	420	2004	64	\N	2575	23.5	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7053.webp	t	\N	f
2225	Massey Ferguson 430	Massey Ferguson	430	2004	74	\N	2575	27.1	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7054.webp	t	\N	f
708	John Deere 6620 Premium	John Deere	6620 Premium	2001	125	\N	8500	40.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7133.webp	t	\N	f
706	John Deere 7515	John Deere	7515	2005	140	\N	8001	43.7	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7122.webp	t	\N	f
707	John Deere 6520 Premium	John Deere	6520 Premium	2001	110	\N	7994	35.6	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7132.webp	f	\N	f
709	John Deere 6820 Premium	John Deere	6820 Premium	2001	135	\N	10498	44.8	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7134.webp	t	\N	f
710	John Deere 6920 Premium	John Deere	6920 Premium	2001	150	\N	10999	49.2	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7135.webp	t	\N	f
711	John Deere 6920S Premium	John Deere	6920S Premium	2001	160	\N	10999	51.7	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7136.webp	t	\N	f
2247	Massey Ferguson 3115	Massey Ferguson	3115	1990	115	\N	4640	42.2	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7144.webp	f	\N	f
3569	Belarus 5290	Belarus	5290	1997	93	\N	3685	34.1	4x4	Diagonal 18.4x34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td7349.webp	t	\N	f
773	John Deere 4049M	John Deere	4049M	2005	49	\N	1710	18	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7569.webp	t	\N	f
774	Massey Ferguson 240	Massey Ferguson	240	1980	46	\N	2079	17	4x4	Diagonal 13.6-28	345	1298	\N	\N	8.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td757.webp	f	\N	f
775	John Deere 4052M	John Deere	4052M	2009	50.8	\N	1710	15	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7570.webp	t	\N	f
776	John Deere 4066M	John Deere	4066M	2009	65	\N	1710	19.9	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7571.webp	t	\N	f
777	John Deere 4044R	John Deere	4044R	2004	42.5	\N	1710	12.3	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7572.webp	f	\N	f
778	John Deere 4049R	John Deere	4049R	2005	49	\N	1710	12.7	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7573.webp	t	\N	f
779	John Deere 4052R	John Deere	4052R	2009	50.8	\N	1710	15	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7574.webp	t	\N	f
780	John Deere 4066R	John Deere	4066R	2009	65	\N	1710	19.9	4x4	Diagonal 44x18-20	457	1118	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7575.webp	t	\N	f
781	Massey Ferguson 240S	Massey Ferguson	240S	1996	46	\N	1846	15	4x2	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td758.webp	f	\N	f
3612	Fiat 355C	Fiat	355C	1971	34.5	\N	2229	12.7	track	Diagonal 71 - 19	1803	3548	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td803.webp	f	\N	f
2869	CaseIH 685XL	CaseIH	685XL	1985	69	\N	3265	23.6	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:52:15.039773	/uploads/tractors/td8192.webp	f	\N	f
2359	Kubota M110GX	Kubota	M110GX	2000	109.5	\N	4180	35.2	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7653.webp	t	\N	f
2360	Kubota M126GX	Kubota	M126GX	2000	125	\N	4705	39.6	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7654.webp	t	\N	f
2361	Kubota M135GX	Kubota	M135GX	2000	135	\N	4705	43.3	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7655.webp	t	\N	f
2366	Massey Ferguson 375	Massey Ferguson	375	1987	67	\N	3266	22.3	4x4	Diagonal 15-30	381	1410	\N	\N	14.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7718.webp	f	\N	f
333	Massey Ferguson 263 (1998-1999)	Massey Ferguson	263	1998	60	\N	2410	20.1	4x4	Diagonal 14.9-28	378	1355	\N	\N	13.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td766.webp	t	\N	f
16	Massey Ferguson 265	Massey Ferguson	265	1975	60	\N	2766	27.8	4x2	Diagonal 16.9-24	429	1339	\N	\N	14.4	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td767.webp	f	\N	f
789	Massey Ferguson 270	Massey Ferguson	270	1983	56	\N	2385	26.2	4x2	Diagonal 16.9-24	429	1339	\N	\N	12.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td768.webp	f	\N	f
790	Massey Ferguson 271	Massey Ferguson	271	1998	65	\N	2780	21.6	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td769.webp	f	\N	f
791	John Deere 6030	John Deere	6030	1972	175	\N	8246	68.1	4x2	Diagonal 20.8-38	528	1863	\N	\N	42	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td77.webp	t	\N	f
792	Massey Ferguson 274	Landini	ferguson 274	1982	55	\N	2714	20.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	12.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td770.webp	f	\N	f
2365	Massey Ferguson 360	Massey Ferguson	360	1987	57	\N	2424	17.3	4x4	Diagonal 13.6-28	345	1298	\N	\N	11	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7717.webp	t	\N	f
794	Massey Ferguson 281	Massey Ferguson	281	1998	75	\N	3009	25.3	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td772.webp	f	\N	f
2368	Massey Ferguson 390	Massey Ferguson	390	1987	76	\N	3295	22.3	4x4	Diagonal 16.9-24	429	1339	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7720.webp	f	\N	f
2369	Massey Ferguson 398	Massey Ferguson	398	1987	89	\N	3469	24.6	4x4	Diagonal 18.4-34	467	1658	\N	\N	18.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7721.webp	t	\N	f
2370	Massey Ferguson 399	Massey Ferguson	399	1987	96	\N	3641	26.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7722.webp	f	\N	f
2372	Kubota B3350	Kubota	B3350	2006	33	\N	860	9.9	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7724.webp	t	\N	f
861	Massey Ferguson 1150	Massey Ferguson	1150	1970	146	\N	6064	76.8	4x2	Diagonal 18.4-34	467	1658	\N	\N	34.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td832.webp	f	\N	f
2466	Kubota MR77	Kubota	MR77	2011	75.9	\N	3140	27.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8320.webp	t	\N	f
862	Massey Ferguson 1155	Massey Ferguson	1155	1973	140	\N	5329	69.5	4x2	Diagonal 18.4-38	467	1760	\N	\N	34.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td833.webp	f	\N	f
870	Massey Ferguson 1205	Iseki	ferguson 1205	1997	15.7	\N	601	5.1	4x4	Diagonal 29x12.00-15	305	737	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td838.webp	f	\N	f
871	Massey Ferguson 1210	Iseki	ferguson 1210	1993	15	\N	720	5.5	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td839.webp	f	\N	f
879	Massey Ferguson 1235	Iseki	ferguson 1235	1997	32	\N	1134	9.4	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td844.webp	f	\N	f
882	John Deere 9470RX	John Deere	9470RX	2016	470	\N	24494	239.1	track	Diagonal 16 - 20	406	1199	\N	\N	74.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8460.webp	f	\N	f
883	John Deere 9520RX	John Deere	9520RX	2016	520	\N	24494	239	track	Diagonal 16 - 20	406	1199	\N	\N	75.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8461.webp	f	\N	f
884	John Deere 9570RX	John Deere	9570RX	2016	570	\N	25174	215.4	track	Diagonal 16 - 20	406	1199	\N	\N	72.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8462.webp	t	\N	f
885	John Deere 9620RX	John Deere	9620RX	2016	620	\N	25174	215.7	track	Diagonal 16 - 20	406	1199	\N	\N	73.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8463.webp	t	\N	f
880	Massey Ferguson 1240	Iseki	ferguson 1240	1992	28.4	\N	1199	8.4	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td845.webp	f	\N	f
881	Massey Ferguson 1250	Iseki	ferguson 1250	1992	33	\N	1245	10	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td846.webp	f	\N	f
3619	Deutz D 15	Deutz	D 15	1959	14	\N	920	5.1	4x2	Diagonal 8-24	203	955	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8465.webp	f	\N	f
889	Massey Ferguson 1260	Iseki	ferguson 1260	1992	40	\N	1451	11.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td847.webp	t	\N	f
895	John Deere 5038D	John Deere	5038D	2000	38	\N	1794	12.5	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8476.webp	f	\N	f
896	John Deere 5039D	John Deere	5039D	2000	39	\N	1794	12.8	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8477.webp	f	\N	f
897	John Deere 5042D	John Deere	5042D	2000	42	\N	1809	13.2	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8478.webp	f	\N	f
898	Massey Ferguson 1500	Massey Ferguson	1500	1971	180	\N	7801	76.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	43.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td848.webp	f	\N	f
900	John Deere 5036C	John Deere	5036C	2000	36	\N	1730	11.4	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8482.webp	f	\N	f
901	John Deere 5039C	John Deere	5039C	2000	39	\N	1730	12.5	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8483.webp	f	\N	f
795	Massey Ferguson 282	Massey Ferguson	282	1982	64	\N	2400	23.5	4x2	Diagonal 13-38	330	1527	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td773.webp	f	\N	f
2079	CaseIH Magnum 225 (2005-2011)	CaseIH	Magnum 225	2005	224	\N	9135	82.2	4x4	Radial 620/70R42	620	1935	\N	\N	44.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7727.webp	t	\N	f
905	John Deere 2030	John Deere	2030	1971	68	\N	2177	28.2	4x2	Diagonal 13.6-28	345	1298	\N	\N	20.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td85.webp	f	\N	f
902	John Deere 5041C	John Deere	5041C	2011	41	\N	1730	15	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8484.webp	f	\N	f
903	John Deere 5042C	John Deere	5042C	2000	42	\N	1730	13.2	4x2	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8485.webp	f	\N	f
904	Massey Ferguson 1505	Massey Ferguson	1505	1974	185	\N	8146	76.6	4x4	Diagonal 23.1-30	587	1759	\N	\N	45.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td849.webp	f	\N	f
906	Massey Ferguson 1800	Massey Ferguson	1800	1971	210	\N	7860	82	4x4	Diagonal 18.4-30	467	1557	\N	\N	48.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td850.webp	f	\N	f
2472	Massey Ferguson 2706E	Massey Ferguson	ferguson 2706e	2016	57.3	\N	1744	17.9	4x4	Diagonal 16.9x24	429	1339	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8507.webp	t	\N	f
2908	CaseIH Farmall 130A	CaseIH	Farmall 130A	2012	123	\N	4000	39.1	4x4	Diagonal 18.4x34	467	1658	\N	\N	25.4	\N	available	2026-09-30 16:55:14.40114	https://cdn.spiritshop.com.br/jmalucelli/image/cache/data/up_system/product-55402/farmall130A_padrao-1000x1000.jpg	t	https://assets.cnhindustrial.com/caseih/LATAM/LATAMASSETS/Folhetos/Tratores/CIH-0157-21 Folheto_Farmall_A_EO_bx.pdf#page=5	t
908	Massey Ferguson 184-4	Landini	ferguson 184 4	1976	68	\N	2893	24.5	4x4	Diagonal 14-30	356	1367	\N	\N	15.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td852.webp	f	\N	f
907	Massey Ferguson 1805	Massey Ferguson	1805	1974	210	\N	8164	83.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	49.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td851.webp	f	\N	f
2476	Kubota M5-091	Kubota	M5 091	2000	92.5	\N	2740	27.9	4x4	Diagonal 18.4-28	467	1506	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8511.webp	t	\N	f
2477	Kubota M5-111	Kubota	M5 111	2000	105.6	\N	2800	35.9	4x4	Diagonal 18.4-28	467	1506	\N	\N	22.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8512.webp	t	\N	f
2478	Kubota M6-101	Kubota	M6 101	2000	104.5	\N	4355	30.1	4x4	Radial 18.4R30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8513.webp	t	\N	f
2479	Kubota M6-111	Kubota	M6 111	2000	114.1	\N	4440	35.4	4x4	Radial 18.4R34	467	1658	\N	\N	23.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8514.webp	t	\N	f
2480	Kubota M6-131	Kubota	M6 131	2000	131.6	\N	4935	46.5	4x4	Radial 18.4R38	467	1760	\N	\N	25.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8515.webp	t	\N	f
2481	Kubota M6-141	Kubota	M6 141	2000	141.4	\N	4935	47.3	4x4	Radial 18.4R38	467	1760	\N	\N	27.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8516.webp	t	\N	f
2482	Massey Ferguson 50X	Massey Ferguson	50X	2000	42	\N	1701	15.4	4x2	Diagonal 11-28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8517.webp	f	\N	f
909	John Deere 3440	John Deere	3440	1979	102	\N	4145	37.4	4x2	Diagonal 23.1x30	587	1759	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8520.webp	f	\N	f
910	Massey Ferguson 2210	Massey Ferguson	2210	1999	55	\N	2570	17.4	4x4	Radial 420/70R28	420	1299	\N	\N	11.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td853.webp	f	\N	f
911	Massey Ferguson 2220 (1999-2000)	Massey Ferguson	2220	1999	63	\N	2245	21.4	4x4	Radial 14.9R28	378	1355	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td854.webp	f	\N	f
912	Massey Ferguson 2640	Massey Ferguson	2640	1980	110	\N	5715	61	4x4	Diagonal 18.4-38	467	1760	\N	\N	23.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td855.webp	f	\N	f
3621	Belarus 7111	Belarus	7111	1975	300	\N	12501	95.4	4x4	Diagonal 28.1x26	714	1874	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8553.webp	f	\N	f
913	Massey Ferguson 2675	Massey Ferguson	2675	1978	100	\N	5080	43	4x2	Diagonal 16.9-38	429	1695	\N	\N	27.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td856.webp	f	\N	f
914	Massey Ferguson 2705	Massey Ferguson	2705	1978	120	\N	5080	58.2	4x2	Diagonal 16.9-38	429	1695	\N	\N	30.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td857.webp	t	\N	f
915	Massey Ferguson 2745	Massey Ferguson	2745	1978	140	\N	5670	68.4	4x2	Diagonal 20.8-38	528	1863	\N	\N	39	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td858.webp	f	\N	f
916	Massey Ferguson 2770	Massey Ferguson	2770	1976	160	\N	5579	58.7	4x2	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td859.webp	f	\N	f
917	John Deere 2630	John Deere	2630	1974	70.37	\N	2630	28.8	4x2	Diagonal 16.9-28	429	1441	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td86.webp	f	\N	f
918	Massey Ferguson 2775	Massey Ferguson	2775	1978	160	\N	6032	77.4	4x2	Diagonal 20.8-38	528	1863	\N	\N	42	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td860.webp	f	\N	f
3622	Fiat 466	Fiat	466	1982	50	\N	2921	18.3	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8608.webp	f	\N	f
3623	Fiat 566	Fiat	566	1982	58	\N	3030	21.3	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8609.webp	f	\N	f
919	Massey Ferguson 2800	Massey Ferguson	2800	1976	190	\N	5896	69.7	4x2	Diagonal 20.8-38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td861.webp	t	\N	f
804	Massey Ferguson 364S	Massey Ferguson	364S	1994	50	\N	2299	18.3	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td787.webp	t	\N	f
2385	Massey Ferguson 299 Advanced	Massey Ferguson	299 Advanced	2002	138.1	\N	4670	43	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7880.webp	t	\N	f
2386	Kubota B40	Kubota	B40	1988	14	\N	550	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td7881.webp	f	\N	f
2486	New Holland L85	New Holland	L85	1996	85	\N	3400	27.9	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8733.webp	t	\N	f
3624	Fiat 666	Fiat	666	1982	68	\N	3299	24.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8610.webp	f	\N	f
920	Massey Ferguson 2805	Massey Ferguson	2805	1978	190	\N	6123	77.3	4x2	Diagonal 20.8-38	528	1863	\N	\N	50.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td862.webp	t	\N	f
921	Massey Ferguson 3050	Massey Ferguson	3050	1986	68	\N	3690	22	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td863.webp	f	\N	f
922	Massey Ferguson 3060	Massey Ferguson	3060	1986	77	\N	3690	24.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td864.webp	f	\N	f
923	Massey Ferguson 3070	Massey Ferguson	3070	1986	80	\N	4623	29.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td865.webp	t	\N	f
924	Massey Ferguson 3075	Massey Ferguson	3075	1993	95	\N	4490	40.9	4x4	Radial 18.4R34	467	1658	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td866.webp	t	\N	f
925	Massey Ferguson 3090	Massey Ferguson	3090	1986	107	\N	4930	34.9	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td867.webp	f	\N	f
926	Massey Ferguson 3120 (1990-1992)	Massey Ferguson	3120	1990	100	\N	4930	38.2	4x4	Radial 18.4R38	467	1760	\N	\N	22.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td868.webp	f	\N	f
927	Massey Ferguson 3120T	Massey Ferguson	3120T	1993	110	\N	5095	40.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td869.webp	t	\N	f
928	Massey Ferguson 3140	Massey Ferguson	3140	1990	115	\N	5210	42.5	4x4	Radial 18.4R38	467	1760	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td870.webp	t	\N	f
929	Massey Ferguson 3505	Massey Ferguson	3505	1983	110	\N	5867	37.1	4x4	Diagonal 18.4-38	467	1760	\N	\N	24.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td871.webp	f	\N	f
2909	CaseIH Optum 270	CaseIH	optum 270	2000	271	\N	10500	109.2	4x4	Radial 480/80R50	480	2038	\N	\N	51.5	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8720.webp	t	\N	f
2910	CaseIH Optum 300	CaseIH	optum 300	2000	300	\N	10500	108.5	4x4	Radial 480/80R50	480	2038	\N	\N	56	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8721.webp	t	\N	f
2488	Kubota L405	Kubota	L405	2000	40	\N	1579	11.9	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8735.webp	f	\N	f
806	John Deere 9420R	John Deere	9420R	2015	420	\N	18810	122.9	4x4	Diagonal 15 - 20	381	1156	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td7883.webp	f	\N	f
3625	Fiat 766	Fiat	766	1984	78	\N	3299	28.6	4x4	Diagonal 84 - 19	2134	4110	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8611.webp	f	\N	f
320	John Deere 8430 (1975-1978)	John Deere	8430	1975	175	\N	9983	100.1	4x4	Diagonal 06 - 20	152	767	\N	\N	44.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td87.webp	t	\N	f
933	Massey Ferguson 3525	Massey Ferguson	3525	1983	130	\N	5942	41.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	26.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td872.webp	t	\N	f
934	Massey Ferguson 3545	Massey Ferguson	3545	1983	147	\N	6032	46.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	30.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td873.webp	t	\N	f
2483	New Holland L60	New Holland	L60	1996	60	\N	3270	22	4x4	Diagonal 7.50-16	191	730	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8730.webp	f	\N	f
2484	New Holland L65	New Holland	L65	1996	65	\N	3200	20.5	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8731.webp	f	\N	f
2485	New Holland L75	New Holland	L75	1996	75	\N	3200	24.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8732.webp	f	\N	f
2487	New Holland L95	New Holland	L95	1996	95	\N	3400	31.6	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8734.webp	t	\N	f
841	Massey Ferguson 699	Massey Ferguson	699	1984	85	\N	4207	38.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td815.webp	f	\N	f
738	John Deere 7210R (2000-2024)	John Deere	7210R	2000	210	\N	10425	62.4	4x4	Radial 320/90R54	320	1948	\N	\N	42.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8151.webp	t	\N	f
669	John Deere 7230R (2000-2024)	John Deere	7230R	2000	230	\N	10384	69.3	4x4	Radial 320/90R54	320	1948	\N	\N	45.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8152.webp	t	\N	f
2437	Massey Ferguson 122	Massey Ferguson	122	2000	24	\N	1170	8.8	4x2	Diagonal 9x28	229	1100	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8195.webp	f	\N	f
857	Massey Ferguson 1130	Massey Ferguson	1130	1964	121	\N	4309	44.2	4x2	Diagonal 24.5-32	622	1871	\N	\N	28.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td828.webp	t	\N	f
2445	Kubota BX1870-1	Kubota	BX1870 1	2015	18	\N	610	5	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8280.webp	f	\N	f
2446	Kubota BX2370-1	Kubota	BX2370 1	2015	23	\N	639	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8281.webp	f	\N	f
2447	Kubota BX2670-1	Kubota	BX2670 1	2015	25.5	\N	664	7.2	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8282.webp	f	\N	f
858	Massey Ferguson 1135	Massey Ferguson	1135	1973	121	\N	4989	62.1	4x2	Diagonal 18.4-38	467	1760	\N	\N	29.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td829.webp	t	\N	f
2468	Kubota MR97	Kubota	MR97	2011	95.6	\N	3339	35.1	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8322.webp	t	\N	f
863	Massey Ferguson 1160	Massey Ferguson	1160	1992	41	\N	1745	13.6	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td834.webp	f	\N	f
941	John Deere 8630	John Deere	8630	1975	275	\N	10954	117.6	4x4	Diagonal 18.4-34	467	1658	\N	\N	57.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td88.webp	t	\N	f
942	Massey Ferguson 4225	Massey Ferguson	4225	1997	65	\N	3145	34.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	14	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td880.webp	f	\N	f
945	Massey Ferguson 4243	Massey Ferguson	4243	1998	85	\N	3508	39.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	17.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td883.webp	t	\N	f
19	John Deere 5045D (2000-2024)	John Deere	5045D	2000	45	\N	1974	13.6	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 02:33:14.821857	/uploads/tractors/td8479.webp	f	\N	f
899	John Deere 5050D	John Deere	5050D	2000	50	\N	1829	15.4	4x2	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8480.webp	t	\N	f
935	Massey Ferguson 3630	Massey Ferguson	3630	1987	115	\N	5320	42.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td874.webp	t	\N	f
936	Massey Ferguson 3650	Massey Ferguson	3650	1987	130	\N	5459	47.7	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td875.webp	t	\N	f
937	Massey Ferguson 3660	Massey Ferguson	3660	1990	140	\N	5965	51.8	4x4	Radial 18.4R38	467	1760	\N	\N	30.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td876.webp	t	\N	f
938	Massey Ferguson 3670	Massey Ferguson	3670	1992	154	\N	6266	56.5	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td877.webp	t	\N	f
939	Massey Ferguson 3680	Massey Ferguson	3680	1988	160	\N	6289	58.7	4x4	Radial 20.8R38	528	1863	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td878.webp	t	\N	f
940	Massey Ferguson 3690	Massey Ferguson	3690	1991	170	\N	5929	62.4	4x4	Radial 18.4R42	467	1861	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td879.webp	t	\N	f
2798	Kubota A-155	Kubota	A 155	1992	15.8	\N	664	5.8	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9923.webp	f	\N	f
1609	Ford 4600 (1976-1984)	Ford	4600	1976	63.1	\N	2032	20.2	4x2	Diagonal 13x28	330	1273	\N	\N	17	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8832.webp	f	\N	f
1931	Ford 4630 (1992-1997)	Ford	4630	1992	63	\N	2676	20.2	4x4	Diagonal 18.4x30	467	1557	\N	\N	14	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5945.webp	f	\N	f
1950	Ford 8630 (1992-1997)	Ford	8630	1992	160	\N	4354	51.4	4x4	Diagonal 18.4x38	467	1760	\N	\N	28.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5965.webp	t	\N	f
2500	New Holland TL60E Exitus	New Holland	TL60E Exitus	2006	61	\N	3180	22.4	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8846.webp	f	\N	f
2399	Massey Ferguson 4708 (2016-4700)	Massey Ferguson	ferguson 4708	2016	80	\N	3508	24.9	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8854.webp	t	\N	f
948	Massey Ferguson 4709 (2016-4700)	Massey Ferguson	ferguson 4709	2016	90	\N	3508	28.6	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8855.webp	t	\N	f
2501	Massey Ferguson 4710	Massey Ferguson	ferguson 4710	2016	100	\N	3508	32.3	4x4	Radial 420/85R34	420	1578	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8856.webp	t	\N	f
2911	CaseIH Farmall 115C	CaseIH	Farmall 115C	2013	115	\N	3600	30.1	4x4	Radial 16.9R34	429	1593	\N	\N	22.3	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8858.webp	t	\N	f
1611	Ford 5600 (1982-1984)	Ford	5600	1982	75	\N	2590	23.8	4x2	Diagonal 16.9-30	429	1492	\N	\N	14.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td267.webp	f	\N	f
2913	CaseIH Farmall 100C	CaseIH	farmall 100c	2015	99	\N	3480	30.4	4x4	Radial 18.4R34	467	1658	\N	\N	18.2	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8862.webp	t	\N	f
2914	CaseIH Farmall 110C	CaseIH	farmall 110c	2015	107	\N	3480	30.7	4x4	Radial 18.4R34	467	1658	\N	\N	20.4	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8863.webp	t	\N	f
2915	CaseIH Farmall 120C	CaseIH	farmall 120c	2015	117	\N	3480	30.7	4x4	Radial 18.4R34	467	1658	\N	\N	21.6	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8864.webp	t	\N	f
3631	Deutz F1M414	Deutz	F1M414	1936	10.8	\N	1129	4	4x2	Diagonal 8.00-20	203	853	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8888.webp	f	\N	f
3632	Deutz F1L514 50	Deutz	F1L514 50	1950	14.8	\N	1285	5.4	4x2	Diagonal 8.00-32	203	1158	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8889.webp	f	\N	f
952	Massey Ferguson 4800	Massey Ferguson	4800	1978	225	\N	12247	112.5	4x4	Diagonal 18.4-38	467	1760	\N	\N	48.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td889.webp	f	\N	f
3633	Deutz F2L514 50	Deutz	F2L514 50	1950	27.6	\N	1850	10.1	4x2	Diagonal 10.00-28	254	1143	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8891.webp	f	\N	f
3635	Deutz F4L514 4	Deutz	F4L514 4	1952	59.2	\N	3025	21.7	4x2	Diagonal 13-30	330	1323	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8896.webp	f	\N	f
3637	Deutz F2L612 4	Deutz	F2L612 4	1954	21.7	\N	1339	8	4x2	Diagonal 8-32	203	1158	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td8899.webp	f	\N	f
599	John Deere 2040 (1976-1982)	John Deere	2040	1976	40	\N	2177	20.6	4x2	Diagonal 13.6-28	345	1298	\N	\N	10.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td89.webp	f	\N	f
953	Massey Ferguson 4840	Massey Ferguson	4840	1978	265	\N	12247	125.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	54.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td890.webp	f	\N	f
638	John Deere 2020 (1967-1972)	John Deere	2020	1967	64	\N	2154	23.5	4x2	Diagonal 12x36	305	1433	\N	\N	18.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8902.webp	f	\N	f
2256	New Holland T4.65 (2015-2017)	New Holland	T4.65	2015	64	\N	2830	18.3	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8904.webp	t	\N	f
2502	New Holland T4.90 (2015-2017)	New Holland	T4.90	2015	86	\N	3480	27.7	4x4	Radial 16.9R30	429	1492	\N	\N	16.7	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8906.webp	t	\N	f
2503	New Holland T4.100 (2015-2017)	New Holland	T4.100	2015	99	\N	3480	31.5	4x4	Radial 16.9R30	429	1492	\N	\N	18.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8907.webp	t	\N	f
2504	New Holland T4.110	New Holland	T4.110	2015	107	\N	3480	35.2	4x4	Radial 16.9R30	429	1492	\N	\N	20.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8908.webp	t	\N	f
2505	New Holland T4.120	New Holland	T4.120	2015	117	\N	3480	38.9	4x4	Radial 18.4R34	467	1658	\N	\N	21.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8909.webp	t	\N	f
954	Massey Ferguson 4880	Massey Ferguson	4880	1978	320	\N	12247	130.2	4x4	Diagonal 18.4-38	467	1760	\N	\N	65.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td891.webp	t	\N	f
1614	Ford 6600 (1976-1984)	Ford	6600	1976	79	\N	2482	27.1	4x2	Diagonal 86.9-30	2207	4514	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8834.webp	f	\N	f
1932	Ford 5030 (1992-1997)	Ford	5030	1992	75	\N	2554	23.8	4x4	Diagonal 13.6-36	345	1502	\N	\N	15.9	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td5946.webp	f	\N	f
947	Massey Ferguson 4253	Massey Ferguson	4253	1997	95	\N	3508	40.8	4x4	Diagonal 18.4-30	467	1557	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td885.webp	t	\N	f
949	Massey Ferguson 4255	Massey Ferguson	4255	1997	95	\N	3508	40.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	19.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td886.webp	t	\N	f
950	Massey Ferguson 4263	Massey Ferguson	4263	1997	100	\N	3830	41.9	4x4	Diagonal 18.4-30	467	1557	\N	\N	22	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td887.webp	f	\N	f
951	Massey Ferguson 4270	Massey Ferguson	4270	1997	110	\N	3871	41.5	4x4	Diagonal 18.4-30	467	1557	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td888.webp	t	\N	f
959	Massey Ferguson 6180	Massey Ferguson	6180	1995	110	\N	5164	40.4	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td896.webp	t	\N	f
2495	New Holland TL55E Exitus	New Holland	TL55E Exitus	2002	62	\N	2659	22.7	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8841.webp	f	\N	f
2496	New Holland TL65E Exitus	New Holland	TL65E Exitus	2002	64	\N	2899	23.5	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8842.webp	f	\N	f
2497	New Holland TL75E Exitus	New Holland	TL75E Exitus	2002	75	\N	3939	27.5	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8843.webp	f	\N	f
2498	New Holland TL85E Exitus	New Holland	TL85E Exitus	2002	85	\N	3939	31.2	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8844.webp	t	\N	f
2499	New Holland TL95E Exitus	New Holland	TL95E Exitus	2002	95	\N	3939	34.9	4x4	Diagonal 18.4x30	467	1557	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8845.webp	t	\N	f
946	Massey Ferguson 4245	Massey Ferguson	4245	1998	85	\N	3508	39.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	17.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td884.webp	t	\N	f
956	Massey Ferguson 5200	McConnell-Marc	ferguson 5200	1989	390	\N	16329	143.1	4x4	Diagonal 89 - 19	2261	4326	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td893.webp	t	\N	f
957	Massey Ferguson 6150	Massey Ferguson	6150	1995	86	\N	4637	31.6	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td894.webp	t	\N	f
958	Massey Ferguson 6170	Massey Ferguson	6170	1995	97	\N	5164	35.6	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td895.webp	f	\N	f
960	Massey Ferguson 6245	Massey Ferguson	6245	1999	75	\N	4229	35.1	4x4	Diagonal 99 - 20	2515	4783	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td897.webp	t	\N	f
2506	Kubota B3000	Kubota	B3000	2010	30	\N	1030	8.4	4x4	Diagonal 10 - 20	254	940	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8971.webp	f	\N	f
955	Massey Ferguson 4900	Massey Ferguson	4900	1980	375	\N	12247	133.8	4x4	Diagonal 18.4-38	467	1760	\N	\N	77.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td892.webp	t	\N	f
2916	CaseIH Farmall 30C	CaseIH	Farmall 30C	2014	32.2	\N	1459	9.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8963.webp	t	\N	f
2917	CaseIH Farmall 35C	CaseIH	Farmall 35C	2014	36.2	\N	1459	10.9	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8964.webp	t	\N	f
2918	CaseIH Farmall 40C	CaseIH	Farmall 40C	2014	40.2	\N	1754	11.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8965.webp	f	\N	f
2919	CaseIH Farmall 45C CVT	CaseIH	Farmall 45C CVT	2015	46	\N	1900	13.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8966.webp	t	\N	f
2920	CaseIH Farmall 50C	CaseIH	Farmall 50C	2014	45.6	\N	1754	13.7	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8967.webp	f	\N	f
2921	CaseIH Farmall 55C CVT	CaseIH	Farmall 55C CVT	2015	54	\N	1900	15.8	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td8968.webp	t	\N	f
2507	Ford 8100	County	8100	1978	115	\N	4117	42.2	4x4	Diagonal 14-38	356	1570	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td8983.webp	f	\N	f
963	John Deere 6110M	John Deere	6110M	2015	110	\N	5007	55.6	4x4	Radial 460/85R38	460	1747	\N	\N	21.2	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8985.webp	t	\N	f
964	John Deere 6120M	John Deere	6120M	2015	120	\N	5210	57.2	4x4	Radial 460/85R38	460	1747	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8986.webp	t	\N	f
965	John Deere 6130M	John Deere	6130M	2015	130	\N	5225	60.2	4x4	Radial 460/85R38	460	1747	\N	\N	25	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8987.webp	t	\N	f
966	John Deere 6145M	John Deere	6145M	2015	145	\N	5533	63.7	4x4	Radial 460/85R38	460	1747	\N	\N	28	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8988.webp	t	\N	f
967	John Deere 6155M	John Deere	6155M	2015	155	\N	5929	61.7	4x4	Radial 460/85R38	460	1747	\N	\N	31	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8989.webp	t	\N	f
969	John Deere 6175M	John Deere	6175M	2015	175	\N	7105	73.6	4x4	Radial 460/85R38	460	1747	\N	\N	34.8	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8990.webp	t	\N	f
970	John Deere 6195M	John Deere	6195M	2015	195	\N	7105	75.4	4x4	Radial 460/85R38	460	1747	\N	\N	37.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td8991.webp	t	\N	f
961	Massey Ferguson 6255	Massey Ferguson	6255	1999	85	\N	4454	39.9	4x4	Diagonal 99 - 20	2515	4783	\N	\N	21.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td898.webp	t	\N	f
973	John Deere 5500	John Deere	5500	1996	83.2	\N	2621	23.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	17	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td90.webp	t	\N	f
968	Massey Ferguson 6265	Massey Ferguson	6265	1999	95	\N	4529	46.8	4x4	Diagonal 99 - 20	2515	4783	\N	\N	22.7	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td899.webp	t	\N	f
974	Massey Ferguson 6270	Massey Ferguson	6270	1999	100	\N	4354	43.1	4x4	Diagonal 99 - 20	2515	4783	\N	\N	22.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td900.webp	t	\N	f
2508	Ford 276	Versatile	276	1988	116	\N	4218	36.7	4x2	Diagonal 88 - 19	2235	4282	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9003.webp	t	\N	f
2509	New Holland TS115	New Holland	TS115	1998	110	\N	4739	34.9	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9016.webp	f	\N	f
2367	Massey Ferguson 383 (1987-1994)	Massey Ferguson	383	1987	69.7	\N	3099	25.6	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9018.webp	f	\N	f
2510	New Holland TS130A	New Holland	holland ts130a	2003	130	\N	5109	40.4	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9019.webp	t	\N	f
2511	New Holland TS100A	New Holland	holland ts100a	2003	100	\N	4560	53.6	4x2	Radial 16.9R38	429	1695	\N	\N	20.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9020.webp	t	\N	f
2512	New Holland TS110A	New Holland	holland ts110a	2003	110	\N	4790	33	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9021.webp	t	\N	f
2513	New Holland TS115A	New Holland	holland ts115a	2003	115	\N	4909	34.9	4x2	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9022.webp	t	\N	f
2514	New Holland TS125A	New Holland	holland ts125a	2003	125	\N	4939	56.8	4x4	Radial 18.4R38	467	1760	\N	\N	25	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9023.webp	t	\N	f
2515	New Holland TS135A	New Holland	holland ts135a	2003	135	\N	4950	52.3	4x4	Radial 16.9R38	429	1695	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9024.webp	t	\N	f
985	John Deere 2440	John Deere	2440	1976	60.65	\N	2154	28.8	4x2	Diagonal 16.9-28	429	1441	\N	\N	15.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td91.webp	f	\N	f
987	John Deere 2038R	John Deere	2038R	2000	37.3	\N	1104	11.2	4x4	Diagonal 14-17.5	356	1049	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9101.webp	t	\N	f
988	John Deere 3025E	John Deere	3025E	2000	24.4	\N	1007	6.4	4x4	Diagonal 41x14-20	356	1041	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9102.webp	f	\N	f
3642	Fiat 800	Fiat	800	2000	80	\N	2960	26	4x2	Diagonal 12x38	305	1483	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9106.webp	f	\N	f
990	John Deere 6145R	John Deere	6145R	2015	145	\N	7723	65.6	4x4	Radial 480/80R42	480	1835	\N	\N	29.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9110.webp	t	\N	f
991	John Deere 6155R	John Deere	6155R	2015	155	\N	7723	68.4	4x4	Radial 480/80R42	480	1835	\N	\N	32.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9111.webp	t	\N	f
2521	Kubota BX1880	Kubota	BX1880	2015	18	\N	606	5	4x4	Diagonal 24x12-12	305	610	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9112.webp	f	\N	f
2522	Kubota BX2380	Kubota	BX2380	2015	23	\N	654	6.5	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9113.webp	f	\N	f
2523	Kubota BX2680	Kubota	BX2680	2015	24.8	\N	689	7.2	4x4	Diagonal 26x12-12	305	660	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9114.webp	f	\N	f
3638	Challenger 1038 (2017-2021)	Challenger	1038	2017	396	\N	14848	147.7	4x4	Radial 420/85R38	420	1679	\N	\N	67	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9120.webp	t	\N	f
3639	Challenger 1042 (2017-2021)	Challenger	1042	2017	435	\N	14848	151.7	4x4	Radial 420/85R38	420	1679	\N	\N	73.4	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9121.webp	t	\N	f
3640	Challenger 1046 (2017-2021)	Challenger	1046	2017	476	\N	14848	154.6	4x4	Radial 750/75R46	750	2293	\N	\N	82.5	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9122.webp	t	\N	f
3641	Challenger 1050 (2017-2021)	Challenger	1050	2017	517	\N	14848	159.1	4x4	Radial 750/75R46	750	2293	\N	\N	89.3	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9123.webp	t	\N	f
3648	Challenger MT955E	Challenger	mt955e	2014	500	\N	21546	146.8	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9124.webp	t	\N	f
3649	Challenger MT965E	Challenger	mt965e	2014	550	\N	21546	155.9	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9125.webp	t	\N	f
3650	Challenger MT975E	Challenger	mt975e	2014	600	\N	21546	155.9	4x4	Radial 710/70R42	710	2061	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9126.webp	t	\N	f
975	Massey Ferguson 6280	Massey Ferguson	6280	1999	110	\N	4814	51.3	4x4	Diagonal 99 - 20	2515	4783	\N	\N	27.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td901.webp	t	\N	f
986	Massey Ferguson 8250	Massey Ferguson	8250	1999	165	\N	8194	60.8	4x4	Diagonal 99 - 20	2515	4783	\N	\N	34.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td910.webp	t	\N	f
989	Massey Ferguson 8260	Massey Ferguson	8260	1999	180	\N	8548	67.7	4x4	Diagonal 99 - 20	2515	4783	\N	\N	40.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td911.webp	t	\N	f
976	Massey Ferguson 6290	Massey Ferguson	6290	1999	120	\N	5245	48.6	4x4	Diagonal 99 - 20	2515	4783	\N	\N	28	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td902.webp	t	\N	f
2516	Massey Ferguson 6445	Massey Ferguson	6445	2003	90	\N	4150	33	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9032.webp	t	\N	f
2517	Massey Ferguson 6455	Massey Ferguson	6455	2003	100	\N	4220	36.7	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9033.webp	t	\N	f
2518	Massey Ferguson 6460	Massey Ferguson	6460	2003	115	\N	4570	42.2	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9034.webp	t	\N	f
2519	Kubota M9580	Kubota	M9580	1991	100	\N	3850	33.4	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9090.webp	t	\N	f
984	John Deere 8400R	John Deere	8400R	2016	400	\N	18000	131.4	4x4	Radial 480/80R50	480	2038	\N	\N	69.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9091.webp	t	\N	f
2520	Massey Ferguson 5150	Massey Ferguson	5150	1998	250	\N	10800	91.7	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9092.webp	t	\N	f
977	Massey Ferguson 8120 (1995-1998)	Massey Ferguson	8120	1995	130	\N	5760	47.7	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td903.webp	t	\N	f
978	Massey Ferguson 8140	Massey Ferguson	8140	1995	145	\N	6350	53.2	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td904.webp	t	\N	f
979	Massey Ferguson 8150	Massey Ferguson	8150	1995	160	\N	6486	58.7	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td905.webp	t	\N	f
980	Massey Ferguson 8160	Massey Ferguson	8160	1995	180	\N	6486	66	4x4	Diagonal 95 - 19	2413	4585	\N	\N	\N	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td906.webp	t	\N	f
981	Massey Ferguson 8220	Massey Ferguson	8220	1999	135	\N	6695	65.4	4x4	Diagonal 99 - 20	2515	4783	\N	\N	32.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td907.webp	t	\N	f
982	Massey Ferguson 8240	Massey Ferguson	8240	1999	145	\N	6980	62	4x4	Diagonal 99 - 20	2515	4783	\N	\N	34.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td908.webp	t	\N	f
983	Massey Ferguson 8245	Massey Ferguson	8245	1999	160	\N	8527	64.1	4x4	Diagonal 99 - 20	2515	4783	\N	\N	37.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td909.webp	t	\N	f
2531	New Holland T8.320	New Holland	holland t8320	2013	250	\N	10069	92.2	4x4	Radial 480/80R50	480	2038	\N	\N	51.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9195.webp	t	\N	f
2532	New Holland T8.350	New Holland	holland t8350	2013	280	\N	10150	116.2	4x4	Radial 480/80R50	480	2038	\N	\N	57.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9196.webp	t	\N	f
2533	New Holland T8.380	New Holland	holland t8380	2013	311	\N	10200	107.2	4x4	Radial 480/80R50	480	2038	\N	\N	60.6	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9197.webp	t	\N	f
2534	New Holland T8.410	New Holland	holland t8410	2013	340	\N	10279	108.7	4x4	Radial 480/80R50	480	2038	\N	\N	65.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9198.webp	t	\N	f
2535	New Holland T8.435	New Holland	holland t8435	2013	380	\N	11880	129.1	4x4	Radial 480/80R50	480	2038	\N	\N	73.8	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9199.webp	t	\N	f
993	Massey Ferguson 8280	Massey Ferguson	8280	1999	225	\N	9770	93.1	4x4	Diagonal 99 - 20	2515	4783	\N	\N	51.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td913.webp	t	\N	f
992	Massey Ferguson 8270	Massey Ferguson	8270	1999	200	\N	9795	92.4	4x4	Diagonal 99 - 20	2515	4783	\N	\N	46.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td912.webp	t	\N	f
994	John Deere 2640	John Deere	2640	1976	70	\N	2630	28.8	4x2	Diagonal 16.9-28	429	1441	\N	\N	18.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td92.webp	f	\N	f
3658	Fiat 715	Fiat	715	1967	70	\N	3319	25.7	4x4	Diagonal 14-34	356	1468	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9204.webp	f	\N	f
2536	Massey Ferguson 4215	Massey Ferguson	ferguson 4215	1997	52	\N	2634	16.4	4x4	Radial 12.4R32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9233.webp	f	\N	f
2537	Massey Ferguson 4220	Massey Ferguson	ferguson 4220	1997	60	\N	2634	19.2	4x4	Radial 12.4R32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9234.webp	t	\N	f
2538	Massey Ferguson 4225	Massey Ferguson	ferguson 4225	1997	65	\N	3396	21.2	4x4	Radial 16.9R30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9235.webp	f	\N	f
2539	Massey Ferguson 4235	Massey Ferguson	ferguson 4235	1997	75	\N	3625	24.8	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9236.webp	f	\N	f
2540	Massey Ferguson 4245	Massey Ferguson	ferguson 4245	1997	85	\N	3729	27.8	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9237.webp	t	\N	f
2541	Massey Ferguson 4255	Massey Ferguson	ferguson 4255	1997	95	\N	3729	31.8	4x4	Radial 16.9R34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9238.webp	t	\N	f
2542	Massey Ferguson 4260	Massey Ferguson	ferguson 4260	1997	100	\N	4105	41.9	4x4	Radial 16.9R38	429	1695	\N	\N	22	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9239.webp	f	\N	f
2543	Massey Ferguson 4270	Massey Ferguson	ferguson 4270	1997	110	\N	4105	36.4	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9240.webp	f	\N	f
3663	Challenger MT297	Iseki	mt297	2003	55.3	\N	1759	16.7	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9241.webp	f	\N	f
3668	Zetor 9245	Zetor	9245	1990	90	\N	4369	29.4	4x4	Diagonal 16.9x38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9274.webp	t	\N	f
3670	Zetor Major 80	Zetor	Major 80	2013	82	\N	3089	27.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9276.webp	t	\N	f
3684	Zetor Proxima Plus 8541	Zetor	Proxima Plus 8541	2007	82	\N	4010	30.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9292.webp	t	\N	f
3685	Zetor Proxima Plus 9541	Zetor	Proxima Plus 9541	2007	90	\N	4010	33	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9293.webp	t	\N	f
3686	Zetor Proxima Plus 10541	Zetor	Proxima Plus 10541	2007	100	\N	4010	36.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9294.webp	t	\N	f
3687	Zetor Proxima Plus 85	Zetor	Proxima Plus 85	2009	82	\N	3739	30.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9295.webp	t	\N	f
3688	Zetor Proxima Plus 95	Zetor	Proxima Plus 95	2009	90	\N	3739	33	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9296.webp	t	\N	f
3689	Zetor Proxima Plus 105	Zetor	Proxima Plus 105	2009	100	\N	3739	36.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9297.webp	t	\N	f
3690	Zetor Proxima Plus 90	Zetor	Proxima Plus 90	2010	87	\N	3739	31.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9298.webp	t	\N	f
3691	Zetor Proxima Plus 100	Zetor	Proxima Plus 100	2010	96	\N	3739	35.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9299.webp	t	\N	f
995	John Deere 2840	John Deere	2840	1977	80.65	\N	3946	37.3	4x2	Diagonal 18.4-34	467	1658	\N	\N	20.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td93.webp	f	\N	f
3693	Zetor Proxima Plus 110	Zetor	Proxima Plus 110	2010	107	\N	3739	39.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9300.webp	t	\N	f
3671	Zetor Major 60	Zetor	Major 60	2015	61.2	\N	3165	22.5	4x4	Diagonal 420/85-30	420	1476	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9277.webp	t	\N	f
3673	Zetor Proxima 65	Zetor	Proxima 65	2009	61	\N	3630	22.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9280.webp	t	\N	f
3674	Zetor Proxima 75	Zetor	Proxima 75	2009	72	\N	3630	26.4	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9281.webp	t	\N	f
3675	Zetor Proxima 85	Zetor	Proxima 85	2009	82	\N	3630	30.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9282.webp	t	\N	f
3676	Zetor Proxima 95	Zetor	Proxima 95	2009	90	\N	3630	33	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9283.webp	t	\N	f
3677	Zetor Proxima 70	Zetor	Proxima 70	2011	65	\N	3630	23.8	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9284.webp	t	\N	f
3678	Zetor Proxima 80	Zetor	Proxima 80	2011	77	\N	3630	28.3	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9285.webp	t	\N	f
3679	Zetor Proxima 90	Zetor	Proxima 90	2011	87	\N	3630	31.9	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9286.webp	t	\N	f
3680	Zetor Proxima 100	Zetor	Proxima 100	2011	96	\N	3630	35.2	4x4	Diagonal 16.9-28	429	1441	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9287.webp	t	\N	f
749	Massey Ferguson 135 (1965-1979)	Massey Ferguson	135	1965	47	\N	1850	13.8	4x2	Diagonal 11-28	279	1186	\N	\N	8.3	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9331.webp	f	\N	f
3697	Zetor Proxima Power 85	Zetor	Proxima Power 85	2009	82	\N	3999	30.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9307.webp	t	\N	f
3698	Zetor Proxima Power 95	Zetor	Proxima Power 95	2009	90	\N	3999	33	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9308.webp	t	\N	f
3699	Zetor Proxima Power 105	Zetor	Proxima Power 105	2009	100	\N	3999	36.7	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9309.webp	t	\N	f
3700	Zetor Proxima Power 115	Zetor	Proxima Power 115	2009	110	\N	3999	40.4	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9310.webp	t	\N	f
3701	Zetor Proxima Power 90	Zetor	Proxima Power 90	2010	87	\N	3999	31.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9311.webp	t	\N	f
3707	Zetor Proxima 110HS	Zetor	Proxima 110HS	2014	106	\N	4257	38.9	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9321.webp	t	\N	f
3708	Zetor Proxima 120HS	Zetor	Proxima 120HS	2014	117	\N	4257	42.9	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9322.webp	t	\N	f
2544	Massey Ferguson 5275	Massey Ferguson	ferguson 5275	2002	75	\N	3800	27.5	4x4	Diagonal 13.6-36	345	1502	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9323.webp	f	\N	f
2546	Massey Ferguson 5290	Massey Ferguson	ferguson 5290	2002	88	\N	5100	32.3	4x4	Diagonal 23.1-26	587	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9325.webp	f	\N	f
2547	Massey Ferguson 5300	Massey Ferguson	ferguson 5300	2002	95	\N	3758	34.9	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9326.webp	t	\N	f
2548	Massey Ferguson 5310	Massey Ferguson	ferguson 5310	2002	105	\N	3758	38.5	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9327.webp	t	\N	f
2549	Massey Ferguson 5320	Massey Ferguson	ferguson 5320	2002	120	\N	4120	44	4x4	Diagonal 23.1-30	587	1759	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9328.webp	f	\N	f
2550	Massey Ferguson 6350	Massey Ferguson	ferguson 6350	2004	190	\N	11400	69.7	4x4	Diagonal 24.5-32	622	1871	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9329.webp	t	\N	f
2551	Massey Ferguson 6360	Massey Ferguson	ferguson 6360	2004	220	\N	11999	80.7	4x4	Diagonal 30.5-32	775	2130	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9330.webp	t	\N	f
3702	Zetor Proxima Power 100	Zetor	Proxima Power 100	2010	96	\N	3999	35.2	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9312.webp	t	\N	f
3703	Zetor Proxima Power 110	Zetor	Proxima Power 110	2010	107	\N	3999	39.3	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9313.webp	t	\N	f
3704	Zetor Proxima Power 120	Zetor	Proxima Power 120	2010	117	\N	3999	42.9	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9314.webp	t	\N	f
3705	Zetor Proxima 80HS	Zetor	Proxima 80HS	2000	76	\N	4257	27.9	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9319.webp	t	\N	f
3706	Zetor Proxima 100HS	Zetor	Proxima 100HS	2014	96	\N	4257	35.2	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9320.webp	t	\N	f
2922	CaseIH Maxxum 135	CaseIH	Maxxum 135	2000	135	\N	5159	49.5	4x4	Radial 460/85R38	460	1747	\N	\N	26.1	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td9337.webp	t	\N	f
2923	CaseIH Maxxum 145	CaseIH	Maxxum 145	2000	145	\N	5694	44	4x4	Radial 460/85R38	460	1747	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td9339.webp	t	\N	f
2924	CaseIH Maxxum 150	CaseIH	Maxxum 150	2000	145	\N	5820	44.4	4x4	Radial 460/85R38	460	1747	\N	\N	28.8	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td9341.webp	t	\N	f
26	John Deere 5115R (2017-2022)	John Deere	5115R	2017	115	\N	4300	42.2	4x4	Radial 540/65R38	540	1667	\N	\N	23.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9346.webp	t	\N	f
27	John Deere 5125R (2000-2024)	John Deere	5125R	2000	125	\N	4300	45.9	4x4	Radial 540/65R38	540	1667	\N	\N	25	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9347.webp	t	\N	f
3709	Zetor Forterra 8641	Zetor	Forterra 8641	1999	85	\N	3949	31.2	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9348.webp	t	\N	f
3710	Zetor Forterra 9641	Zetor	Forterra 9641	1999	95	\N	3949	34.9	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9349.webp	t	\N	f
3711	Zetor Forterra 11641	Zetor	Forterra 11641	1999	110	\N	4450	40.4	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9350.webp	t	\N	f
3712	Zetor Forterra 11441	Zetor	Forterra 11441	2002	110	\N	4617	40.4	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9354.webp	t	\N	f
3713	Zetor 11741	Zetor	11741	2002	120	\N	4696	44	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9355.webp	t	\N	f
3733	Zetor Crystal 150	Zetor	Crystal 150	2016	144	\N	5840	52.8	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9394.webp	t	\N	f
3743	Zetor 11050	Zetor	11050	2008	107	\N	3900	34.5	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9404.webp	t	\N	f
3744	Zetor 12050	Zetor	12050	2008	120	\N	4102	38.2	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9405.webp	t	\N	f
3734	Zetor Crystal 160	Zetor	Crystal 160	2016	163	\N	5840	59.8	4x4	Radial 650/65R38	650	1810	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9395.webp	t	\N	f
3735	Zetor 7020	Zetor	7020	2008	70	\N	3125	23.1	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9396.webp	t	\N	f
3736	Zetor 7040	Zetor	7040	2008	70	\N	3488	23.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9397.webp	t	\N	f
3737	Zetor 8020	Zetor	8020	2008	82	\N	3193	26.8	4x2	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9398.webp	t	\N	f
3738	Zetor 8040	Zetor	8040	2008	82	\N	3556	26.8	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9399.webp	t	\N	f
971	John Deere 4040 (1978-1982)	John Deere	4040	1978	90	\N	4368	39.7	4x2	Diagonal 18.4-38	467	1760	\N	\N	25.4	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td94.webp	f	\N	f
3739	Zetor 9020	Zetor	9020	2008	93	\N	3216	29.7	4x2	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9400.webp	t	\N	f
3740	Zetor 9040	Zetor	9040	2008	93	\N	3578	29.7	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9401.webp	t	\N	f
3741	Zetor 9050	Zetor	9050	2008	93	\N	3878	30.5	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9402.webp	t	\N	f
3742	Zetor 10050	Zetor	10050	2008	100	\N	3887	32.7	4x4	Radial 18.4R34	467	1658	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9403.webp	t	\N	f
2553	New Holland T7.175	New Holland	holland t7175	2011	140	\N	5800	62.9	4x4	Radial 460/85R38	460	1747	\N	\N	27.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9452.webp	t	\N	f
2554	New Holland T7.190	New Holland	holland t7190	2011	150	\N	5800	63.3	4x4	Radial 460/85R38	460	1747	\N	\N	29.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9453.webp	t	\N	f
2555	New Holland T7.230	New Holland	holland t7230	2011	180	\N	6950	73.9	4x4	Radial 480/80R46	480	1936	\N	\N	36	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9455.webp	t	\N	f
2556	New Holland T7.245	New Holland	holland t7245	2011	200	\N	6950	77.3	4x4	Radial 480/80R46	480	1936	\N	\N	39.4	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9456.webp	t	\N	f
2557	New Holland T7.290	New Holland	holland t7290	2000	270	\N	10299	0.8	4x4	Radial 480/80R50	480	2038	\N	\N	51.5	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9459.webp	t	\N	f
2558	New Holland T7.315	New Holland	holland t7315	2000	300	\N	10299	108.5	4x4	Radial 480/80R50	480	2038	\N	\N	56	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9460.webp	t	\N	f
2559	New Holland Boomer 35	New Holland	holland boomer 35	2014	35	\N	1271	10.9	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9464.webp	t	\N	f
2560	New Holland Boomer 40	New Holland	holland boomer 40	2014	40	\N	1271	12.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9465.webp	t	\N	f
2561	New Holland Boomer 45	New Holland	holland boomer 45	2014	45	\N	1553	14	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9466.webp	t	\N	f
2562	New Holland Boomer 50	New Holland	holland boomer 50	2014	50	\N	1553	15.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9467.webp	t	\N	f
2563	New Holland Boomer 55	New Holland	holland boomer 55	2000	55	\N	1553	17.1	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9468.webp	t	\N	f
2564	New Holland Boomer 45D	New Holland	holland boomer 45d	2000	45	\N	1876	13.2	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9469.webp	f	\N	f
2565	New Holland Boomer 50D	New Holland	holland boomer 50d	2000	50	\N	1876	14.7	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9470.webp	f	\N	f
2566	New Holland Boomer 46D	New Holland	holland boomer 46d	2000	46	\N	1900	12.5	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9471.webp	t	\N	f
2567	New Holland Boomer 54D	New Holland	holland boomer 54d	2000	54	\N	1900	15	4x4	Diagonal 14.9-24	378	1253	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9472.webp	t	\N	f
2568	New Holland Workmaster 33	New Holland	holland workmaster 33	2015	32.2	\N	1391	9.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9473.webp	t	\N	f
2569	New Holland Workmaster 37	New Holland	holland workmaster 37	2015	36.2	\N	1391	10.9	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9474.webp	t	\N	f
2570	New Holland Workmaster 35	New Holland	holland workmaster 35	2017	35	\N	1391	10.9	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9475.webp	t	\N	f
2571	New Holland Workmaster 40	New Holland	holland workmaster 40	2017	40	\N	1391	12.5	4x4	Diagonal 11.2x24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9476.webp	t	\N	f
2572	New Holland Workmaster 50	New Holland	holland workmaster 50	2009	53	\N	2294	16.5	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9477.webp	t	\N	f
2573	New Holland Workmaster 60	New Holland	holland workmaster 60	2009	60	\N	2294	18.7	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9478.webp	t	\N	f
2574	New Holland Workmaster 70	New Holland	holland workmaster 70	2009	70	\N	2294	22.4	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9479.webp	t	\N	f
972	John Deere 4240 (1978-1982)	John Deere	4240	1978	110	\N	4944	51.1	4x2	Diagonal 18.4-34	467	1658	\N	\N	29.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td95.webp	f	\N	f
1348	CaseIH 5120 Maxxum (1990-1997)	CaseIH	5120 Maxxum	1990	94	\N	4700	28.3	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9510.webp	t	\N	f
1350	CaseIH 5130 Maxxum (1990-1997)	CaseIH	5130 Maxxum	1990	105	\N	4799	31.6	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9511.webp	f	\N	f
1351	CaseIH 5140 Maxxum (1990-1997)	CaseIH	5140 Maxxum	1990	117	\N	4910	34.5	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9512.webp	t	\N	f
2925	CaseIH 5150 Maxxum	CaseIH	5150 Maxxum	1992	132	\N	5600	41.1	4x4	Diagonal 18.4x38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:55:14.40114	/uploads/tractors/td9513.webp	t	\N	f
2575	Massey Ferguson 37	Massey Ferguson	37	1962	44.5	\N	1441	16.3	4x2	Diagonal 10-28	254	1143	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9515.webp	f	\N	f
2576	Massey Ferguson 820	Massey Ferguson	820	1957	20	\N	999	7.3	4x2	Diagonal 9-24	229	998	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9554.webp	f	\N	f
2577	Kubota GT-3	Kubota	GT 3	1992	20.7	\N	870	7.6	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9567.webp	f	\N	f
2578	Kubota GT-5	Kubota	GT 5	1992	22.7	\N	874	8.3	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9568.webp	f	\N	f
2579	Kubota GT-8	Kubota	GT 8	1992	25.6	\N	884	9.4	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9569.webp	f	\N	f
2580	Kubota GT-19	Kubota	GT 19	2001	18.8	\N	850	6.9	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9570.webp	f	\N	f
2581	Kubota GT-21	Kubota	GT 21	2001	20.7	\N	879	7.6	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9571.webp	f	\N	f
2582	Kubota GT-23	Kubota	GT 23	2001	22.7	\N	899	8.3	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9572.webp	f	\N	f
2583	Kubota GT-26	Kubota	GT 26	2001	25.6	\N	909	9.4	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9573.webp	f	\N	f
2584	Kubota GT-30	Kubota	GT 30	2001	29.6	\N	949	10.9	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9574.webp	f	\N	f
2585	Kubota GL200	Kubota	GL200	1993	19.7	\N	1094	7.2	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9576.webp	f	\N	f
2586	Kubota GL220	Kubota	GL220	1993	21.7	\N	1094	8	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9577.webp	f	\N	f
817	John Deere 6195R (2011-2014)	John Deere	6195R	2011	195	\N	8400	71.5	4x4	Diagonal 15 - 20	381	1156	\N	\N	39	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td9481.webp	t	\N	f
2587	Kubota GL240	Kubota	GL240	1993	23.7	\N	1104	8.7	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9578.webp	f	\N	f
2588	Kubota GL260	Kubota	GL260	1993	25.6	\N	1179	8.8	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9579.webp	f	\N	f
2591	Kubota GL300	Kubota	GL300	1993	29.6	\N	1270	10.1	4x4	Diagonal 12.4-26	315	1196	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9582.webp	f	\N	f
2592	Kubota GL320	Kubota	GL320	1993	31.6	\N	1280	10.6	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9583.webp	f	\N	f
2593	Kubota GL338	Kubota	GL338	1993	32.6	\N	1280	10.2	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9584.webp	f	\N	f
2596	Kubota GL201	Kubota	GL201	1996	20.7	\N	1094	7.6	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9587.webp	f	\N	f
2597	Kubota GL221	Kubota	GL221	1996	22.7	\N	1094	8.3	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9588.webp	f	\N	f
2598	Kubota GL241	Kubota	GL241	1996	24.7	\N	1104	8.7	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9589.webp	f	\N	f
2599	Kubota GL261	Kubota	GL261	1996	26.7	\N	1179	9.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9590.webp	f	\N	f
2615	Kubota GL32	Kubota	GL32	1990	31.6	\N	1210	10.2	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9633.webp	f	\N	f
2617	Kubota L1-265	Kubota	L1 265	1986	25.6	\N	1149	9.3	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9635.webp	f	\N	f
2618	Kubota L1-285	Kubota	L1 285	1986	27.6	\N	1190	10	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9636.webp	f	\N	f
2619	Kubota L1-275	Kubota	L1 275	1988	26.6	\N	1114	9.4	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9637.webp	f	\N	f
2620	Kubota L1-295	Kubota	L1 295	1988	28.1	\N	1190	9.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9638.webp	f	\N	f
2621	Kubota L1-315	Kubota	L1 315	1988	30.1	\N	1230	10.3	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9639.webp	f	\N	f
2623	Kubota GM49	Kubota	GM49	1998	48.3	\N	2090	16.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9642.webp	f	\N	f
2624	Kubota GM56	Kubota	GM56	1998	55.1	\N	2150	18.7	4x4	Diagonal 12.4-32	315	1348	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9643.webp	f	\N	f
2625	Kubota GM64	Kubota	GM64	1998	63	\N	2229	21.5	4x4	Diagonal 12.4-36	315	1450	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9644.webp	f	\N	f
2626	Kubota GM73	Kubota	GM73	1998	71.9	\N	2259	25.1	4x4	Diagonal 16.9-30	429	1492	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9645.webp	f	\N	f
2627	Kubota GM75	Kubota	GM75	1998	74	\N	2820	27.1	4x4	Diagonal 13.9-36	353	1515	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9646.webp	t	\N	f
2628	Kubota GM82	Kubota	GM82	1998	80.9	\N	2820	29.7	4x4	Diagonal 13.9-36	353	1515	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9647.webp	t	\N	f
2629	Kubota GM90	Kubota	GM90	1998	87.8	\N	2869	32.2	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9648.webp	t	\N	f
2630	Kubota Bb260	Kubota	Bb260	2000	25.6	\N	964	9.4	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9649.webp	f	\N	f
2631	Kubota GB13	Kubota	GB13	1997	12.9	\N	524	4.7	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9650.webp	f	\N	f
2632	Kubota GB14	Kubota	GB14	1997	13.8	\N	539	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9651.webp	f	\N	f
2633	Kubota GB15	Kubota	GB15	1997	14.8	\N	570	5.4	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9652.webp	f	\N	f
2635	Kubota GB130	Kubota	GB130	2002	12.9	\N	504	4.7	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9654.webp	f	\N	f
2636	Kubota GB140	Kubota	GB140	2002	13.8	\N	539	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9655.webp	f	\N	f
2637	Kubota GB150	Kubota	GB150	2002	14.8	\N	565	5.4	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9656.webp	f	\N	f
2638	Kubota GB170	Kubota	GB170	2002	16.8	\N	565	6.2	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9657.webp	f	\N	f
2639	Kubota GB115	Kubota	GB115	2004	10.3	\N	479	3.8	4x4	Diagonal 7-14	178	658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9658.webp	f	\N	f
2640	Kubota GB135	Kubota	GB135	2004	12.9	\N	504	4.7	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9659.webp	f	\N	f
2641	Kubota GB145	Kubota	GB145	2004	13.8	\N	539	5.1	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9660.webp	f	\N	f
2642	Kubota GB155	Kubota	GB155	2004	14.8	\N	565	5.4	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9661.webp	f	\N	f
2643	Kubota GB175	Kubota	GB175	2004	16.8	\N	565	6.2	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9662.webp	f	\N	f
2644	Kubota GB16	Kubota	GB16	1997	15.8	\N	679	5.8	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9663.webp	f	\N	f
2645	Kubota GB18	Kubota	GB18	1997	17.7	\N	689	6.5	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9664.webp	f	\N	f
2646	Kubota GB20	Kubota	GB20	1997	19.7	\N	699	7.2	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9665.webp	f	\N	f
2647	Kubota GB160	Kubota	GB160	2002	15.8	\N	689	5.8	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9666.webp	f	\N	f
2648	Kubota GB180	Kubota	GB180	2002	17.7	\N	694	6.5	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9667.webp	f	\N	f
2649	Kubota GB200	Kubota	GB200	2002	19.7	\N	704	7.2	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9668.webp	f	\N	f
2654	Kubota KL30	Kubota	KL30	1999	29.6	\N	1300	10.9	4x4	Diagonal 12.4-26	315	1196	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9674.webp	f	\N	f
2655	Kubota KL33	Kubota	KL33	1999	32.6	\N	1309	12	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9675.webp	f	\N	f
327	John Deere 4640 (1978-1982)	John Deere	4640	1978	155	\N	6509	68.3	4x2	Diagonal 18.4-38	467	1760	\N	\N	37.9	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td97.webp	t	\N	f
2686	Kubota KL345	Kubota	KL345	2008	33.5	\N	1329	12.3	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9710.webp	f	\N	f
2687	Kubota KL385	Kubota	KL385	2008	37.4	\N	1520	13.7	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9711.webp	f	\N	f
2688	Kubota KL415	Kubota	KL415	2008	41.4	\N	1539	15.2	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9712.webp	f	\N	f
2696	Kubota M90	Kubota	M90	2002	88.8	\N	3289	32.6	4x4	Diagonal 13.9-36	353	1515	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9727.webp	t	\N	f
2697	Kubota M100	Kubota	M100	2002	98.7	\N	3640	36.2	4x4	Diagonal 16.9-34	429	1593	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9728.webp	t	\N	f
2698	Kubota M115	Kubota	M115	2002	113.3	\N	4070	41.6	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9729.webp	f	\N	f
2699	Kubota M125	Kubota	M125	2002	123.2	\N	4070	41	4x4	Diagonal 18.4-38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9730.webp	t	\N	f
2711	Kubota M100G	Kubota	M100G	2009	98.7	\N	3665	36.2	4x4	Diagonal 13.6-38	345	1552	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9742.webp	t	\N	f
2712	Kubota M110G	Kubota	M110G	2009	108.5	\N	3709	39.8	4x4	Diagonal 16.9-38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9743.webp	t	\N	f
2713	Kubota M115G	Kubota	M115G	2009	113.5	\N	4340	41.6	4x4	Radial 420/85R38	420	1679	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9744.webp	t	\N	f
2714	Kubota M125G	Kubota	M125G	2009	123.2	\N	4419	45.2	4x4	Radial 18.4R38	467	1760	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9745.webp	t	\N	f
2715	Kubota M135G	Kubota	M135G	2009	133.2	\N	4465	48.9	4x4	Radial 520/70R38	520	1693	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9746.webp	t	\N	f
2721	Kubota B17X	Kubota	B17X	2000	16.8	\N	575	6.2	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9755.webp	f	\N	f
2736	Kubota FT220	Kubota	FT220	2012	21.7	\N	909	8	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9775.webp	f	\N	f
2737	Kubota FT240	Kubota	FT240	2012	23.7	\N	914	8.7	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9776.webp	f	\N	f
2738	Kubota FT300	Kubota	FT300	2012	29.6	\N	1010	10.9	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9777.webp	f	\N	f
2742	Kubota JB16	Kubota	JB16	2006	16.2	\N	590	5.9	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9785.webp	f	\N	f
2744	Kubota JB11X	Kubota	JB11X	2006	10.3	\N	504	3.8	4x4	Diagonal 7-16	178	709	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9791.webp	f	\N	f
2745	Kubota JB13X	Kubota	JB13X	2006	13.3	\N	550	4.9	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9792.webp	f	\N	f
2746	Kubota JB15X	Kubota	JB15X	2006	14.8	\N	575	5.4	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9793.webp	f	\N	f
2747	Kubota JB17X	Kubota	JB17X	2006	16.8	\N	575	6.2	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9794.webp	f	\N	f
2748	Kubota JB19X	Kubota	JB19X	2006	18.8	\N	575	6.9	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9795.webp	f	\N	f
998	John Deere 4840	John Deere	4840	1978	180	\N	6758	77	4x2	Diagonal 18.4-38	467	1760	\N	\N	43.5	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td98.webp	t	\N	f
2749	Kubota KB16	Kubota	KB16	2005	15.8	\N	689	5.8	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9800.webp	f	\N	f
2750	Kubota KB18	Kubota	KB18	2005	17.7	\N	694	6.5	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9801.webp	f	\N	f
2751	Kubota KB20	Kubota	KB20	2005	19.7	\N	704	7.2	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9802.webp	f	\N	f
2752	Kubota KB165	Kubota	KB165	2008	16.2	\N	689	5.9	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9803.webp	f	\N	f
2753	Kubota KB185	Kubota	KB185	2008	18.2	\N	694	6.7	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9804.webp	f	\N	f
2754	Kubota KB205	Kubota	KB205	2008	20.3	\N	704	7.4	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9805.webp	f	\N	f
2755	Kubota KB225	Kubota	KB225	2008	22.1	\N	714	8.1	4x4	Diagonal 9.5-22	241	969	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9806.webp	f	\N	f
2756	Kubota KB17X	Kubota	KB17X	2009	16.8	\N	689	6.2	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9810.webp	f	\N	f
2757	Kubota KB19X	Kubota	KB19X	2009	18.8	\N	694	6.9	4x4	Diagonal 8.3-22	211	917	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9811.webp	f	\N	f
2758	Kubota KB21X	Kubota	KB21X	2009	20.7	\N	704	7.6	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9812.webp	f	\N	f
2759	Kubota KB23X	Kubota	KB23X	2009	22.1	\N	704	8.1	4x4	Diagonal 9.5-20	241	918	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9813.webp	f	\N	f
2600	Kubota GL277	Kubota	GL277	1996	26.7	\N	1179	9.6	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9591.webp	f	\N	f
2601	Kubota GL281	Kubota	GL281	1996	28.6	\N	1215	10.1	4x4	Diagonal 11.2-26	284	1144	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9592.webp	f	\N	f
2602	Kubota GL301	Kubota	GL301	1996	30.6	\N	1270	10.7	4x4	Diagonal 12.4-26	315	1196	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9593.webp	f	\N	f
2603	Kubota GL321	Kubota	GL321	1996	32.6	\N	1280	10.9	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9594.webp	f	\N	f
2604	Kubota GL337	Kubota	GL337	1996	32.6	\N	1280	10.2	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9595.webp	f	\N	f
2605	Kubota GL367	Kubota	GL367	1996	35.5	\N	1440	11.6	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9596.webp	f	\N	f
2606	Kubota GL417	Kubota	GL417	1996	41.4	\N	1440	13.9	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9597.webp	f	\N	f
2607	Kubota GL467	Kubota	GL467	1996	45.3	\N	1440	15.2	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9598.webp	f	\N	f
218	John Deere 4440 (1978-1982)	John Deere	4440	1978	130	\N	5343	59.6	4x2	Diagonal 18.4-38	467	1760	\N	\N	32.6	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td96.webp	t	\N	f
2608	Kubota GL19	Kubota	GL19	1990	18.7	\N	1020	6.9	4x4	Diagonal 8.3-24	211	968	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9626.webp	f	\N	f
2609	Kubota GL21	Kubota	GL21	1990	20.7	\N	1040	7.6	4x4	Diagonal 9.5-32	241	1223	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9627.webp	f	\N	f
2610	Kubota GL23	Kubota	GL23	1990	22.7	\N	1060	8.3	4x4	Diagonal 9.5-24	241	1020	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9628.webp	f	\N	f
2611	Kubota GL25	Kubota	GL25	1990	24.7	\N	1129	8.5	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9629.webp	f	\N	f
2612	Kubota GL26	Kubota	GL26	1990	25.6	\N	1200	8.9	4x4	Diagonal 11.2-24	284	1093	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9630.webp	f	\N	f
2613	Kubota GL27	Kubota	GL27	1990	26.6	\N	1149	9.2	4x4	Diagonal 11.2-26	284	1144	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9631.webp	f	\N	f
2614	Kubota GL29	Kubota	GL29	1990	28.6	\N	1190	9.9	4x4	Diagonal 12.4-24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9632.webp	f	\N	f
2776	Kubota KL31Z	Kubota	KL31Z	2013	30.6	\N	1644	11.2	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9838.webp	f	\N	f
2777	Kubota KL34Z	Kubota	KL34Z	2013	33.5	\N	1644	12.3	4x4	Diagonal 13.6-24	345	1197	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9839.webp	f	\N	f
2778	Kubota KL37Z	Kubota	KL37Z	2012	36.5	\N	1809	13.4	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9840.webp	f	\N	f
2779	Kubota KL40Z	Kubota	KL40Z	2012	39.4	\N	1814	14.5	4x4	Diagonal 12.4-28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9841.webp	f	\N	f
2780	Kubota KL44Z	Kubota	KL44Z	2012	43.5	\N	1814	16	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9842.webp	f	\N	f
2781	Kubota KL48Z	Kubota	KL48Z	2012	47.3	\N	1920	17.4	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9843.webp	f	\N	f
2782	Kubota KL53Z	Kubota	KL53Z	2012	52.3	\N	1920	19.2	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9844.webp	f	\N	f
2783	Kubota KL58Z	Kubota	KL58Z	2012	57.3	\N	1920	21	4x4	Diagonal 13.6-28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9845.webp	f	\N	f
2785	Massey Ferguson 2604H	Massey Ferguson	2604H	2000	45	\N	2234	13.9	4x4	Diagonal 12.4x28	315	1247	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9872.webp	t	\N	f
2786	Massey Ferguson 2605H	Massey Ferguson	2605H	2000	55	\N	2446	16.9	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9873.webp	t	\N	f
2787	Massey Ferguson 2606H	Massey Ferguson	2606H	2000	65	\N	2590	20.2	4x4	Diagonal 14.9x28	378	1355	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9874.webp	t	\N	f
2788	Massey Ferguson 2607H	Massey Ferguson	2607H	2000	74	\N	2659	23.5	4x4	Diagonal 16.9x28	429	1441	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9875.webp	t	\N	f
999	John Deere 850	Yanmar	deere 850	1978	25	\N	1088	12	4x4	Diagonal 11.2-24	284	1093	\N	\N	6.1	\N	available	2026-09-30 14:36:34.06389	/uploads/tractors/td99.webp	f	\N	f
2789	Massey Ferguson 4707	Massey Ferguson	ferguson 4707	2016	70	\N	3508	21.3	4x4	Radial 420/85R30	420	1476	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9913.webp	t	\N	f
2790	Massey Ferguson 5711SL	Massey Ferguson	ferguson 5711sl	2016	105	\N	4799	32.3	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9914.webp	t	\N	f
2791	Massey Ferguson 5712SL	Massey Ferguson	ferguson 5712sl	2016	115	\N	4799	34.9	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9915.webp	t	\N	f
2792	Massey Ferguson 5713SL	Massey Ferguson	ferguson 5713sl	2016	125	\N	4799	38.2	4x4	Radial 460/85R34	460	1646	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9916.webp	t	\N	f
2794	Massey Ferguson 4365	Massey Ferguson	ferguson 4365	2002	112	\N	3749	34.7	4x4	Radial 16.9R38	429	1695	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9918.webp	t	\N	f
2795	Kubota A-15	Kubota	A 15	1988	15.3	\N	650	5.6	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9920.webp	f	\N	f
2796	Kubota A-17	Kubota	A 17	1988	16.8	\N	659	6.2	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9921.webp	f	\N	f
2797	Kubota A-19	Kubota	A 19	1988	18.3	\N	669	6.7	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9922.webp	f	\N	f
2799	Kubota A-175	Kubota	A 175	1992	17.3	\N	684	6.3	4x4	Diagonal 8-18	203	803	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9924.webp	f	\N	f
2800	Kubota A-195	Kubota	A 195	1992	18.7	\N	694	6.9	4x4	Diagonal 8.3-20	211	866	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9925.webp	f	\N	f
3745	Zetor Major HT 45	Zetor	Major HT 45	2000	46	\N	1920	12.7	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9927.webp	f	\N	f
3746	Zetor Major HT 55	Zetor	Major HT 55	2000	55.1	\N	1920	15.5	4x4	Diagonal 13.6-26	345	1248	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9928.webp	t	\N	f
3747	Zetor Major HS 65	Zetor	Major HS 65	2000	67	\N	2519	22.7	4x4	Diagonal 14.9-30	378	1405	\N	\N	\N	\N	available	2026-09-30 18:02:54.57488	/uploads/tractors/td9929.webp	t	\N	f
2801	Kubota B1830	Kubota	B1830	2007	17.7	\N	704	5.4	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9935.webp	f	\N	f
2802	Kubota B2230	Kubota	B2230	2007	21.7	\N	719	6.5	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9936.webp	f	\N	f
2803	Kubota B2530	Kubota	B2530	2007	24.7	\N	724	7.2	4x4	Diagonal 9.5-18	241	867	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9937.webp	f	\N	f
1565	Kubota B3030 (2007-2013)	Kubota	B3030	2007	29.4	\N	840	8.3	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9938.webp	f	\N	f
2804	Kubota B2050	Kubota	B2050	2018	19.7	\N	724	5.9	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9939.webp	f	\N	f
2805	Kubota B2350	Kubota	B2350	2018	22.7	\N	754	6.4	4x4	Diagonal 9.5-16	241	817	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9940.webp	f	\N	f
2371	Kubota B2650 (2018-2025)	Kubota	B2650	2018	25.6	\N	754	7.4	4x4	Diagonal 9.5-18	241	867	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9941.webp	f	\N	f
2806	Kubota B3150	Kubota	B3150	2018	30.6	\N	845	8.5	4x4	Diagonal 12.4-16	315	942	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9942.webp	f	\N	f
2793	Kubota L1801	Kubota	L1801	1976	17.8	\N	782	6.5	4x4	Diagonal 8-22	203	904	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9917.webp	f	\N	f
2241	New Holland 8030	New Holland	8030	2002	120	\N	9750	44.8	4x4	Diagonal 18.4-34	467	1658	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/20120503113523_1S_8030_00406E.jpg	t	https://www.dinissanmaquinaria.com/wp-content/uploads/2022/03/8030.pdf	t
2811	Kubota B1121	Kubota	B1121	2000	10.7	\N	600	3.9	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9947.webp	f	\N	f
2812	Kubota B1161	Kubota	B1161	2000	14.8	\N	630	5.4	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9948.webp	f	\N	f
2813	Kubota B1181	Kubota	B1181	2000	17.4	\N	640	6.4	4x4	Diagonal 8-16	203	752	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9949.webp	f	\N	f
2814	Kubota B1241	Kubota	B1241	2000	21.5	\N	739	7.9	4x4	Radial 280/70R18	280	849	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9950.webp	f	\N	f
2815	Massey Ferguson 8727S	Massey Ferguson	ferguson 8727s	2018	270	\N	10800	101.2	4x4	Radial 650/85R42	650	2172	\N	\N	51.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9959.webp	t	\N	f
2816	Massey Ferguson 8730S	Massey Ferguson	ferguson 8730s	2018	295	\N	10800	100.5	4x4	Radial 650/85R42	650	2172	\N	\N	54.1	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9960.webp	t	\N	f
2817	Massey Ferguson 8732S	Massey Ferguson	ferguson 8732s	2018	320	\N	10800	100	4x4	Radial 650/85R42	650	2172	\N	\N	59	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9961.webp	t	\N	f
2818	Massey Ferguson 8735S	Massey Ferguson	ferguson 8735s	2018	350	\N	10800	99	4x4	Radial 650/85R42	650	2172	\N	\N	64.3	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9962.webp	t	\N	f
2819	Massey Ferguson 8737S	Massey Ferguson	ferguson 8737s	2018	370	\N	10800	97.3	4x4	Radial 650/85R42	650	2172	\N	\N	66.2	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9963.webp	t	\N	f
2820	Massey Ferguson 8740S	Massey Ferguson	ferguson 8740s	2018	400	\N	10800	130.2	4x4	Radial 650/85R42	650	2172	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9964.webp	t	\N	f
2821	Massey Ferguson 1735M	Massey Ferguson	ferguson 1735m	2013	36.2	\N	1529	10.1	4x4	Diagonal 12.4x24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9966.webp	t	\N	f
2822	Massey Ferguson 1740M	Massey Ferguson	ferguson 1740m	2013	40	\N	1529	11.4	4x4	Diagonal 12.4x24	315	1145	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9967.webp	t	\N	f
2823	Massey Ferguson 1750M	Massey Ferguson	ferguson 1750m	2013	48.8	\N	1789	14	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9968.webp	t	\N	f
2824	Massey Ferguson 1755M	Massey Ferguson	ferguson 1755m	2013	53.9	\N	1799	15.2	4x4	Diagonal 13.6x28	345	1298	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9969.webp	t	\N	f
2825	Massey Ferguson 1760M	Massey Ferguson	ferguson 1760m	2013	59.9	\N	1799	16.9	4x4	Diagonal 16.9x26	429	1390	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9970.webp	t	\N	f
2826	Massey Ferguson 835	Massey Ferguson	835	1958	33	\N	1480	12.1	4x2	Diagonal 11x28	279	1186	\N	\N	\N	\N	available	2026-09-30 16:49:10.296204	/uploads/tractors/td9983.webp	f	\N	f
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (user_id, name, email, password, role_id, status, registration_date, last_session) FROM stdin;
6	waos	waos@waos.com	$2b$10$J/yUt2qM9cLm7tq21pZqeOkrvD7BLYeNDSLguWbmjzzWGT2YkBec6	2	active	2026-04-26 18:19:25.028408	2026-09-13 16:37:06.936601
7	Adminwaos	waos@admin.com	$2b$10$FeVI9QtrOXMI7aMWMCx2EO5mKjN4kngL3cTQBAr2lNX2emnOWRPAu	2	active	2026-05-13 15:50:01.395958	2026-09-13 16:37:08.055531
8	Local Admin	admin@local.dev	$2b$10$oU95EN/FCh9uWXwGwqkb/elQNnBwfp45R7K23FHj1iKyQKBEBaMi2	2	active	2026-06-11 22:35:56.789245	2026-09-13 16:37:09.174994
1	Administrator	admin@maqagr.com	$2b$10$7kCdWH1tnn0EF1Fkba2g1unog29kedAsLL6shlx.AkRyNZah6gWlm	1	active	2026-04-21 06:46:20.86626	2026-09-16 18:07:23.034063
9	QA Tester	qa-debug@maqagr.com	$2b$10$VcsKOYUliHyTt0ai/h/vHe5a1tzxar9NgB4iZALO1Eq13vyoP3IZ6	2	active	2026-09-16 18:07:11.244111	2026-09-16 18:07:23.156319
\.


--
-- Name: implement_implement_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.implement_implement_id_seq', 300, true);


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

SELECT pg_catalog.setval('public.query_history_history_id_seq', 7, true);


--
-- Name: query_query_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.query_query_id_seq', 7, true);


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

SELECT pg_catalog.setval('public.terrain_terrain_id_seq', 6, true);


--
-- Name: tractor_tractor_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tractor_tractor_id_seq', 4554, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_user_id_seq', 9, true);


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

\unrestrict wK3p4Cv6HtfseAOql2hHYKfRzp9ckCIIRm3thpQQiTXBTS5dSBGHPjUD38houjd

