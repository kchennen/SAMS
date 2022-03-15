--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

-- Started on 2022-03-15 13:20:02 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 27 (class 2615 OID 2367707)
-- Name: sams_userdata; Type: SCHEMA; Schema: -; Owner: sams
--

CREATE SCHEMA sams_userdata;


ALTER SCHEMA sams_userdata OWNER TO sams;

--
-- TOC entry 53968 (class 1247 OID 2367709)
-- Name: symptom_status; Type: TYPE; Schema: sams_userdata; Owner: sams
--

CREATE TYPE sams_userdata.symptom_status AS ENUM (
    'present',
    'absent',
    'weakened',
    'worsened'
);


ALTER TYPE sams_userdata.symptom_status OWNER TO sams;

--
-- TOC entry 13667 (class 1259 OID 2367717)
-- Name: sequence_user_no; Type: SEQUENCE; Schema: sams_userdata; Owner: sams
--

CREATE SEQUENCE sams_userdata.sequence_user_no
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sams_userdata.sequence_user_no OWNER TO sams;

SET default_table_access_method = heap;

--
-- TOC entry 13668 (class 1259 OID 2367719)
-- Name: doctors; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.doctors (
    number integer DEFAULT nextval('sams_userdata.sequence_user_no'::regclass) NOT NULL,
    firstname character varying,
    lastname character varying,
    department character varying,
    sex character varying
);


ALTER TABLE sams_userdata.doctors OWNER TO sams;

--
-- TOC entry 13669 (class 1259 OID 2367726)
-- Name: pat2doc; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.pat2doc (
    doc_no integer NOT NULL,
    pat_no integer NOT NULL
);


ALTER TABLE sams_userdata.pat2doc OWNER TO sams;

--
-- TOC entry 13670 (class 1259 OID 2367729)
-- Name: sequence_pat_no; Type: SEQUENCE; Schema: sams_userdata; Owner: sams
--

CREATE SEQUENCE sams_userdata.sequence_pat_no
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sams_userdata.sequence_pat_no OWNER TO sams;

--
-- TOC entry 13671 (class 1259 OID 2367731)
-- Name: patients; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.patients (
    number integer DEFAULT nextval('sams_userdata.sequence_pat_no'::regclass) NOT NULL,
    external_id character varying NOT NULL,
    sex character varying,
    creation_date date NOT NULL,
    consanguinity boolean,
    created_by integer NOT NULL
);


ALTER TABLE sams_userdata.patients OWNER TO sams;

--
-- TOC entry 13672 (class 1259 OID 2367738)
-- Name: sequence_visits; Type: SEQUENCE; Schema: sams_userdata; Owner: sams
--

CREATE SEQUENCE sams_userdata.sequence_visits
    START WITH 20
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sams_userdata.sequence_visits OWNER TO sams;

--
-- TOC entry 13673 (class 1259 OID 2367740)
-- Name: sessions; Type: TABLE; Schema: sams_userdata; Owner: postgres
--

CREATE TABLE sams_userdata.sessions (
    session_id text NOT NULL,
    expires timestamp without time zone NOT NULL,
    email text,
    number integer NOT NULL,
    name text,
    role text,
    experimental_features boolean DEFAULT false
);


ALTER TABLE sams_userdata.sessions OWNER TO postgres;

--
-- TOC entry 13674 (class 1259 OID 2367746)
-- Name: sessions_sequence; Type: SEQUENCE; Schema: sams_userdata; Owner: postgres
--

CREATE SEQUENCE sams_userdata.sessions_sequence
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sams_userdata.sessions_sequence OWNER TO postgres;

--
-- TOC entry 13675 (class 1259 OID 2367748)
-- Name: share2doc; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.share2doc (
    pat_no integer NOT NULL,
    security_code integer NOT NULL,
    creation_date timestamp without time zone NOT NULL
);


ALTER TABLE sams_userdata.share2doc OWNER TO sams;

--
-- TOC entry 13676 (class 1259 OID 2367751)
-- Name: users; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.users (
    number integer DEFAULT nextval('sams_userdata.sequence_user_no'::regclass) NOT NULL,
    email character varying NOT NULL,
    password character varying NOT NULL,
    role character varying DEFAULT 'pat'::character varying NOT NULL,
    deleted date,
    experimental_features boolean DEFAULT false
);


ALTER TABLE sams_userdata.users OWNER TO sams;

--
-- TOC entry 13677 (class 1259 OID 2367759)
-- Name: visits; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.visits (
    number integer DEFAULT nextval('sams_userdata.sequence_visits'::regclass) NOT NULL,
    submit_date date NOT NULL,
    visit_date date NOT NULL,
    pat_number integer,
    created_by integer,
    deprecated boolean
);


ALTER TABLE sams_userdata.visits OWNER TO sams;

--
-- TOC entry 13678 (class 1259 OID 2367763)
-- Name: visits_mxn_alphacodes; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.visits_mxn_alphacodes (
    visit_number integer NOT NULL,
    status sams_userdata.symptom_status NOT NULL,
    alpha_number integer NOT NULL
);


ALTER TABLE sams_userdata.visits_mxn_alphacodes OWNER TO sams;

--
-- TOC entry 13679 (class 1259 OID 2367766)
-- Name: visits_mxn_hpo; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.visits_mxn_hpo (
    visit_number integer NOT NULL,
    status sams_userdata.symptom_status NOT NULL,
    hpo_id integer NOT NULL
);


ALTER TABLE sams_userdata.visits_mxn_hpo OWNER TO sams;

--
-- TOC entry 13680 (class 1259 OID 2367769)
-- Name: visits_mxn_omim; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.visits_mxn_omim (
    visit_number integer NOT NULL,
    mim integer NOT NULL,
    status sams_userdata.symptom_status NOT NULL
);


ALTER TABLE sams_userdata.visits_mxn_omim OWNER TO sams;

--
-- TOC entry 13681 (class 1259 OID 2367772)
-- Name: visits_mxn_orphanet; Type: TABLE; Schema: sams_userdata; Owner: sams
--

CREATE TABLE sams_userdata.visits_mxn_orphanet (
    visit_number integer NOT NULL,
    status sams_userdata.symptom_status NOT NULL,
    disorder_id integer NOT NULL
);


ALTER TABLE sams_userdata.visits_mxn_orphanet OWNER TO sams;

--
-- TOC entry 80247 (class 2606 OID 2367776)
-- Name: doctors doctors_pkey; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.doctors
    ADD CONSTRAINT doctors_pkey PRIMARY KEY (number);


--
-- TOC entry 80251 (class 2606 OID 2367778)
-- Name: pat2doc pat2doc_pkey; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.pat2doc
    ADD CONSTRAINT pat2doc_pkey PRIMARY KEY (doc_no, pat_no);


--
-- TOC entry 80253 (class 2606 OID 2367780)
-- Name: patients pk_pat_no; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.patients
    ADD CONSTRAINT pk_pat_no PRIMARY KEY (number);


--
-- TOC entry 80261 (class 2606 OID 2367782)
-- Name: users pk_user_no; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.users
    ADD CONSTRAINT pk_user_no PRIMARY KEY (number);


--
-- TOC entry 80271 (class 2606 OID 2367784)
-- Name: visits_mxn_alphacodes pk_visits_mxn_alpha_number; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_alphacodes
    ADD CONSTRAINT pk_visits_mxn_alpha_number PRIMARY KEY (visit_number, alpha_number);


--
-- TOC entry 80273 (class 2606 OID 2367786)
-- Name: visits_mxn_hpo pk_visits_mxn_hpo; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_hpo
    ADD CONSTRAINT pk_visits_mxn_hpo PRIMARY KEY (visit_number, hpo_id);


--
-- TOC entry 80275 (class 2606 OID 2367788)
-- Name: visits_mxn_omim pk_visits_mxn_omim; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_omim
    ADD CONSTRAINT pk_visits_mxn_omim PRIMARY KEY (visit_number, mim);


--
-- TOC entry 80277 (class 2606 OID 2367790)
-- Name: visits_mxn_orphanet pk_visits_mxn_orpha; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_orphanet
    ADD CONSTRAINT pk_visits_mxn_orpha PRIMARY KEY (visit_number, disorder_id);


--
-- TOC entry 80257 (class 2606 OID 2367792)
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: sams_userdata; Owner: postgres
--

ALTER TABLE ONLY sams_userdata.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (session_id);


--
-- TOC entry 80259 (class 2606 OID 2367794)
-- Name: share2doc share2doc_pkey; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.share2doc
    ADD CONSTRAINT share2doc_pkey PRIMARY KEY (security_code, pat_no);


--
-- TOC entry 80255 (class 2606 OID 2367938)
-- Name: patients u_patients_externalid; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.patients
    ADD CONSTRAINT u_patients_externalid UNIQUE (external_id, created_by);


--
-- TOC entry 80263 (class 2606 OID 2367796)
-- Name: users unique_email; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.users
    ADD CONSTRAINT unique_email UNIQUE (email);


--
-- TOC entry 80249 (class 2606 OID 2367798)
-- Name: doctors unique_no; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.doctors
    ADD CONSTRAINT unique_no UNIQUE (number);


--
-- TOC entry 80265 (class 2606 OID 2367800)
-- Name: users unique_user_number; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.users
    ADD CONSTRAINT unique_user_number UNIQUE (number);


--
-- TOC entry 80267 (class 2606 OID 2367802)
-- Name: visits visits_pkey; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits
    ADD CONSTRAINT visits_pkey PRIMARY KEY (number);


--
-- TOC entry 80269 (class 2606 OID 2367804)
-- Name: visits visits_unique; Type: CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits
    ADD CONSTRAINT visits_unique UNIQUE (number);


--
-- TOC entry 80278 (class 2606 OID 2367805)
-- Name: doctors docs_users_fkey; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.doctors
    ADD CONSTRAINT docs_users_fkey FOREIGN KEY (number) REFERENCES sams_userdata.users(number) ON DELETE CASCADE;


--
-- TOC entry 80280 (class 2606 OID 2367810)
-- Name: pat2doc fk_doc_no; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.pat2doc
    ADD CONSTRAINT fk_doc_no FOREIGN KEY (doc_no) REFERENCES sams_userdata.doctors(number);


--
-- TOC entry 80283 (class 2606 OID 2367815)
-- Name: share2doc fk_pat; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.share2doc
    ADD CONSTRAINT fk_pat FOREIGN KEY (pat_no) REFERENCES sams_userdata.patients(number);


--
-- TOC entry 80284 (class 2606 OID 2367820)
-- Name: visits fk_pat_no; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits
    ADD CONSTRAINT fk_pat_no FOREIGN KEY (pat_number) REFERENCES sams_userdata.patients(number);


--
-- TOC entry 80281 (class 2606 OID 2367825)
-- Name: pat2doc fk_pat_no; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.pat2doc
    ADD CONSTRAINT fk_pat_no FOREIGN KEY (pat_no) REFERENCES sams_userdata.patients(number);


--
-- TOC entry 80282 (class 2606 OID 2367830)
-- Name: patients fk_patients_created_by; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.patients
    ADD CONSTRAINT fk_patients_created_by FOREIGN KEY (created_by) REFERENCES sams_userdata.users(number);


--
-- TOC entry 80285 (class 2606 OID 2367835)
-- Name: visits fk_user_no; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits
    ADD CONSTRAINT fk_user_no FOREIGN KEY (created_by) REFERENCES sams_userdata.users(number);


--
-- TOC entry 80279 (class 2606 OID 2367845)
-- Name: doctors user_number; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.doctors
    ADD CONSTRAINT user_number FOREIGN KEY (number) REFERENCES sams_userdata.users(number) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 80286 (class 2606 OID 2367850)
-- Name: visits_mxn_alphacodes visits_mxn_alphacodes_alpha_number_fkey; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_alphacodes
    ADD CONSTRAINT visits_mxn_alphacodes_alpha_number_fkey FOREIGN KEY (alpha_number) REFERENCES sams_data.alpha_codes(alpha_number);


--
-- TOC entry 80288 (class 2606 OID 2367855)
-- Name: visits_mxn_hpo visits_mxn_hpo_hpo_id_fkey; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_hpo
    ADD CONSTRAINT visits_mxn_hpo_hpo_id_fkey FOREIGN KEY (hpo_id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80287 (class 2606 OID 2367860)
-- Name: visits_mxn_alphacodes visits_mxn_number; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_alphacodes
    ADD CONSTRAINT visits_mxn_number FOREIGN KEY (visit_number) REFERENCES sams_userdata.visits(number) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;


--
-- TOC entry 80290 (class 2606 OID 2367865)
-- Name: visits_mxn_omim visits_mxn_number; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_omim
    ADD CONSTRAINT visits_mxn_number FOREIGN KEY (visit_number) REFERENCES sams_userdata.visits(number) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 80292 (class 2606 OID 2367870)
-- Name: visits_mxn_orphanet visits_mxn_number; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_orphanet
    ADD CONSTRAINT visits_mxn_number FOREIGN KEY (visit_number) REFERENCES sams_userdata.visits(number) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 80289 (class 2606 OID 2367875)
-- Name: visits_mxn_hpo visits_mxn_number; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_hpo
    ADD CONSTRAINT visits_mxn_number FOREIGN KEY (visit_number) REFERENCES sams_userdata.visits(number) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 80291 (class 2606 OID 2367880)
-- Name: visits_mxn_omim visits_mxn_omim_mim_fkey; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_omim
    ADD CONSTRAINT visits_mxn_omim_mim_fkey FOREIGN KEY (mim) REFERENCES sams_data.omim(mim);


--
-- TOC entry 80293 (class 2606 OID 2367885)
-- Name: visits_mxn_orphanet visits_mxn_orphanet_disorder_id_fkey; Type: FK CONSTRAINT; Schema: sams_userdata; Owner: sams
--

ALTER TABLE ONLY sams_userdata.visits_mxn_orphanet
    ADD CONSTRAINT visits_mxn_orphanet_disorder_id_fkey FOREIGN KEY (disorder_id) REFERENCES sams_data.orphanet(disorder_id);


--
-- TOC entry 80429 (class 0 OID 0)
-- Dependencies: 27
-- Name: SCHEMA sams_userdata; Type: ACL; Schema: -; Owner: sams
--

REVOKE ALL ON SCHEMA sams_userdata FROM sams;
GRANT ALL ON SCHEMA sams_userdata TO sams WITH GRANT OPTION;
GRANT ALL ON SCHEMA sams_userdata TO PUBLIC;


--
-- TOC entry 80430 (class 0 OID 0)
-- Dependencies: 13667
-- Name: SEQUENCE sequence_user_no; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON SEQUENCE sams_userdata.sequence_user_no TO postgres;


--
-- TOC entry 80431 (class 0 OID 0)
-- Dependencies: 13668
-- Name: TABLE doctors; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.doctors TO genetik;


--
-- TOC entry 80432 (class 0 OID 0)
-- Dependencies: 13669
-- Name: TABLE pat2doc; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.pat2doc TO genetik;


--
-- TOC entry 80433 (class 0 OID 0)
-- Dependencies: 13671
-- Name: TABLE patients; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.patients TO genetik;


--
-- TOC entry 80434 (class 0 OID 0)
-- Dependencies: 13673
-- Name: TABLE sessions; Type: ACL; Schema: sams_userdata; Owner: postgres
--

GRANT ALL ON TABLE sams_userdata.sessions TO PUBLIC;
GRANT ALL ON TABLE sams_userdata.sessions TO genetik;


--
-- TOC entry 80435 (class 0 OID 0)
-- Dependencies: 13674
-- Name: SEQUENCE sessions_sequence; Type: ACL; Schema: sams_userdata; Owner: postgres
--

GRANT ALL ON SEQUENCE sams_userdata.sessions_sequence TO PUBLIC;


--
-- TOC entry 80436 (class 0 OID 0)
-- Dependencies: 13675
-- Name: TABLE share2doc; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.share2doc TO genetik;


--
-- TOC entry 80437 (class 0 OID 0)
-- Dependencies: 13676
-- Name: TABLE users; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.users TO genetik;


--
-- TOC entry 80438 (class 0 OID 0)
-- Dependencies: 13677
-- Name: TABLE visits; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.visits TO genetik;


--
-- TOC entry 80439 (class 0 OID 0)
-- Dependencies: 13678
-- Name: TABLE visits_mxn_alphacodes; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.visits_mxn_alphacodes TO genetik;


--
-- TOC entry 80440 (class 0 OID 0)
-- Dependencies: 13679
-- Name: TABLE visits_mxn_hpo; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.visits_mxn_hpo TO genetik;


--
-- TOC entry 80441 (class 0 OID 0)
-- Dependencies: 13680
-- Name: TABLE visits_mxn_omim; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.visits_mxn_omim TO genetik;


--
-- TOC entry 80442 (class 0 OID 0)
-- Dependencies: 13681
-- Name: TABLE visits_mxn_orphanet; Type: ACL; Schema: sams_userdata; Owner: sams
--

GRANT ALL ON TABLE sams_userdata.visits_mxn_orphanet TO genetik;


-- Completed on 2022-03-15 13:20:12 CET

--
-- PostgreSQL database dump complete
--

