--
-- PostgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 13.4

-- Started on 2022-03-15 13:20:37 CET

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
-- TOC entry 19 (class 2615 OID 2367528)
-- Name: sams_data; Type: SCHEMA; Schema: -; Owner: sams
--

CREATE SCHEMA sams_data;


ALTER SCHEMA sams_data OWNER TO sams;

SET default_table_access_method = heap;

--
-- TOC entry 13651 (class 1259 OID 2367529)
-- Name: alpha_codes; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.alpha_codes (
    alpha_number integer NOT NULL,
    alpha_key text NOT NULL,
    alpha_star text,
    alpha_extra text,
    alpha_pk text,
    orpha_number integer,
    text text NOT NULL
);


ALTER TABLE sams_data.alpha_codes OWNER TO sams;

--
-- TOC entry 13652 (class 1259 OID 2367535)
-- Name: hpo_children; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_children (
    id integer NOT NULL,
    children_path character varying(100) NOT NULL
);


ALTER TABLE sams_data.hpo_children OWNER TO sams;

--
-- TOC entry 13653 (class 1259 OID 2367538)
-- Name: hpo_hpo_mxn_genes; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_hpo_mxn_genes (
    gene_no integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE sams_data.hpo_hpo_mxn_genes OWNER TO sams;

--
-- TOC entry 13654 (class 1259 OID 2367541)
-- Name: hpo_hpo_mxn_genes_cumulated; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_hpo_mxn_genes_cumulated (
    gene_no integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE sams_data.hpo_hpo_mxn_genes_cumulated OWNER TO sams;

--
-- TOC entry 13655 (class 1259 OID 2367544)
-- Name: hpo_hpo_mxn_omim; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_hpo_mxn_omim (
    id integer NOT NULL,
    mim integer NOT NULL
);


ALTER TABLE sams_data.hpo_hpo_mxn_omim OWNER TO sams;

--
-- TOC entry 13656 (class 1259 OID 2367547)
-- Name: hpo_hpo_mxn_orphanet; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_hpo_mxn_orphanet (
    id integer NOT NULL,
    disorder_id smallint NOT NULL,
    frequency smallint,
    diagnostic_criterion boolean
);


ALTER TABLE sams_data.hpo_hpo_mxn_orphanet OWNER TO sams;

--
-- TOC entry 13657 (class 1259 OID 2367550)
-- Name: hpo_parents; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_parents (
    id integer NOT NULL,
    parents_path character varying(100) NOT NULL
);


ALTER TABLE sams_data.hpo_parents OWNER TO sams;

--
-- TOC entry 13658 (class 1259 OID 2367553)
-- Name: hpo_relevance_notused; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_relevance_notused (
    id integer NOT NULL,
    genecount smallint NOT NULL
);


ALTER TABLE sams_data.hpo_relevance_notused OWNER TO sams;

--
-- TOC entry 13659 (class 1259 OID 2367556)
-- Name: hpo_synonyms; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_synonyms (
    id integer NOT NULL,
    synonym character varying(500) NOT NULL,
    language_id smallint NOT NULL
);


ALTER TABLE sams_data.hpo_synonyms OWNER TO sams;

--
-- TOC entry 13660 (class 1259 OID 2367559)
-- Name: hpo_term_mxn_opposites; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_term_mxn_opposites (
    id integer NOT NULL,
    opposite_id integer NOT NULL
);


ALTER TABLE sams_data.hpo_term_mxn_opposites OWNER TO sams;

--
-- TOC entry 13661 (class 1259 OID 2367562)
-- Name: hpo_terms; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_terms (
    id integer NOT NULL,
    term character varying(200) NOT NULL,
    comment character varying(200),
    cumulated_relevance smallint,
    relevance smallint
);


ALTER TABLE sams_data.hpo_terms OWNER TO sams;

--
-- TOC entry 13662 (class 1259 OID 2367565)
-- Name: hpo_terms_mxn_terms; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_terms_mxn_terms (
    parent_id integer NOT NULL,
    child_id integer NOT NULL
);


ALTER TABLE sams_data.hpo_terms_mxn_terms OWNER TO sams;

--
-- TOC entry 13663 (class 1259 OID 2367568)
-- Name: hpo_terms_otherlanguages; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.hpo_terms_otherlanguages (
    hpo_id integer NOT NULL,
    language smallint NOT NULL,
    term character varying(200),
    comment character varying
);


ALTER TABLE sams_data.hpo_terms_otherlanguages OWNER TO sams;

--
-- TOC entry 13664 (class 1259 OID 2367574)
-- Name: languages; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.languages (
    id smallint NOT NULL,
    language character varying(20)
);


ALTER TABLE sams_data.languages OWNER TO sams;

--
-- TOC entry 13665 (class 1259 OID 2367577)
-- Name: omim; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.omim (
    mim integer NOT NULL,
    omim_text character varying(500000),
    clinical_symptoms character varying(6000),
    title character varying(2000),
    allelic_variants character varying(500000),
    class public.omim_class
);


ALTER TABLE sams_data.omim OWNER TO sams;

--
-- TOC entry 13666 (class 1259 OID 2367583)
-- Name: orphanet; Type: TABLE; Schema: sams_data; Owner: sams
--

CREATE TABLE sams_data.orphanet (
    disorder_id smallint NOT NULL,
    orpha_number integer NOT NULL,
    title character varying(200) NOT NULL
);


ALTER TABLE sams_data.orphanet OWNER TO sams;

--
-- TOC entry 80251 (class 2606 OID 2367587)
-- Name: alpha_codes alpha_codes_pkey; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.alpha_codes
    ADD CONSTRAINT alpha_codes_pkey PRIMARY KEY (alpha_number);


--
-- TOC entry 80270 (class 2606 OID 2367589)
-- Name: hpo_synonyms hpo_synonyms_pkey; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_synonyms
    ADD CONSTRAINT hpo_synonyms_pkey PRIMARY KEY (id, synonym, language_id);


--
-- TOC entry 80280 (class 2606 OID 2367591)
-- Name: hpo_terms_otherlanguages hpo_terms_otherlanguages_pkey; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_otherlanguages
    ADD CONSTRAINT hpo_terms_otherlanguages_pkey PRIMARY KEY (hpo_id, language);


--
-- TOC entry 80286 (class 2606 OID 2367593)
-- Name: orphanet orphanet_orpha_number_key; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.orphanet
    ADD CONSTRAINT orphanet_orpha_number_key UNIQUE (orpha_number);


--
-- TOC entry 80288 (class 2606 OID 2367595)
-- Name: orphanet orphanet_pkey; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.orphanet
    ADD CONSTRAINT orphanet_pkey PRIMARY KEY (disorder_id);


--
-- TOC entry 80256 (class 2606 OID 2367597)
-- Name: hpo_hpo_mxn_genes pk_hpo_mxn_genes; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_genes
    ADD CONSTRAINT pk_hpo_mxn_genes PRIMARY KEY (gene_no, id);


--
-- TOC entry 80260 (class 2606 OID 2367599)
-- Name: hpo_hpo_mxn_genes_cumulated pk_hpo_mxn_genes_cumulated; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_genes_cumulated
    ADD CONSTRAINT pk_hpo_mxn_genes_cumulated PRIMARY KEY (gene_no, id);


--
-- TOC entry 80262 (class 2606 OID 2367601)
-- Name: hpo_hpo_mxn_omim pk_hpo_mxn_omim; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_omim
    ADD CONSTRAINT pk_hpo_mxn_omim PRIMARY KEY (id, mim);


--
-- TOC entry 80264 (class 2606 OID 2367603)
-- Name: hpo_hpo_mxn_orphanet pk_hpo_mxn_orphanet; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_orphanet
    ADD CONSTRAINT pk_hpo_mxn_orphanet PRIMARY KEY (id, disorder_id);


--
-- TOC entry 80282 (class 2606 OID 2367605)
-- Name: languages pk_languages; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.languages
    ADD CONSTRAINT pk_languages PRIMARY KEY (id);


--
-- TOC entry 80284 (class 2606 OID 2367607)
-- Name: omim pk_omim; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.omim
    ADD CONSTRAINT pk_omim PRIMARY KEY (mim);


--
-- TOC entry 80266 (class 2606 OID 2367609)
-- Name: hpo_parents pk_parents_parents_path; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_parents
    ADD CONSTRAINT pk_parents_parents_path PRIMARY KEY (id, parents_path);


--
-- TOC entry 80274 (class 2606 OID 2367611)
-- Name: hpo_terms pk_terms; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms
    ADD CONSTRAINT pk_terms PRIMARY KEY (id);


--
-- TOC entry 80278 (class 2606 OID 2367613)
-- Name: hpo_terms_mxn_terms pk_terms_mxn_terms; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_mxn_terms
    ADD CONSTRAINT pk_terms_mxn_terms PRIMARY KEY (parent_id, child_id);


--
-- TOC entry 80268 (class 2606 OID 2367615)
-- Name: hpo_relevance_notused relevance_pkey; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_relevance_notused
    ADD CONSTRAINT relevance_pkey PRIMARY KEY (id);


--
-- TOC entry 80253 (class 2606 OID 2367617)
-- Name: hpo_children u_children_children_path; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_children
    ADD CONSTRAINT u_children_children_path PRIMARY KEY (id, children_path);


--
-- TOC entry 80276 (class 2606 OID 2367619)
-- Name: hpo_terms u_terms_term; Type: CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms
    ADD CONSTRAINT u_terms_term UNIQUE (term);


--
-- TOC entry 80257 (class 1259 OID 2367620)
-- Name: i_hpo_mxn_genes_cumulated_genes; Type: INDEX; Schema: sams_data; Owner: sams
--

CREATE INDEX i_hpo_mxn_genes_cumulated_genes ON sams_data.hpo_hpo_mxn_genes_cumulated USING btree (gene_no);


--
-- TOC entry 80258 (class 1259 OID 2367621)
-- Name: i_hpo_mxn_genes_cumulated_hpo; Type: INDEX; Schema: sams_data; Owner: sams
--

CREATE INDEX i_hpo_mxn_genes_cumulated_hpo ON sams_data.hpo_hpo_mxn_genes_cumulated USING btree (id);


--
-- TOC entry 80254 (class 1259 OID 2367622)
-- Name: i_hpo_mxn_genes_hpo; Type: INDEX; Schema: sams_data; Owner: sams
--

CREATE INDEX i_hpo_mxn_genes_hpo ON sams_data.hpo_hpo_mxn_genes USING btree (id);


--
-- TOC entry 80272 (class 1259 OID 2367623)
-- Name: i_terms_term; Type: INDEX; Schema: sams_data; Owner: sams
--

CREATE INDEX i_terms_term ON sams_data.hpo_terms USING btree (term);


--
-- TOC entry 80271 (class 1259 OID 2367624)
-- Name: term_mxn_opposites_id_idx; Type: INDEX; Schema: sams_data; Owner: sams
--

CREATE INDEX term_mxn_opposites_id_idx ON sams_data.hpo_term_mxn_opposites USING btree (id);


--
-- TOC entry 80289 (class 2606 OID 2367625)
-- Name: alpha_codes alpha_codes_orpha_number_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.alpha_codes
    ADD CONSTRAINT alpha_codes_orpha_number_fkey FOREIGN KEY (orpha_number) REFERENCES sams_data.orphanet(orpha_number);


--
-- TOC entry 80291 (class 2606 OID 2367630)
-- Name: hpo_hpo_mxn_genes_cumulated fk_hpo_mxn_genes_cumulated_hpo; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_genes_cumulated
    ADD CONSTRAINT fk_hpo_mxn_genes_cumulated_hpo FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80292 (class 2606 OID 2367635)
-- Name: hpo_hpo_mxn_omim fk_hpo_mxn_omim_hpo; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_omim
    ADD CONSTRAINT fk_hpo_mxn_omim_hpo FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80293 (class 2606 OID 2367640)
-- Name: hpo_hpo_mxn_orphanet fk_hpo_mxn_orphanet_hpo; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_hpo_mxn_orphanet
    ADD CONSTRAINT fk_hpo_mxn_orphanet_hpo FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80294 (class 2606 OID 2367645)
-- Name: hpo_parents fk_parents_hpo_id; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_parents
    ADD CONSTRAINT fk_parents_hpo_id FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80290 (class 2606 OID 2367650)
-- Name: hpo_children fk_parents_hpo_id; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_children
    ADD CONSTRAINT fk_parents_hpo_id FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80295 (class 2606 OID 2367655)
-- Name: hpo_synonyms fk_synonyms_term_id; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_synonyms
    ADD CONSTRAINT fk_synonyms_term_id FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80299 (class 2606 OID 2367660)
-- Name: hpo_terms_mxn_terms fk_terms_mxn_terms_child_id; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_mxn_terms
    ADD CONSTRAINT fk_terms_mxn_terms_child_id FOREIGN KEY (child_id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80300 (class 2606 OID 2367665)
-- Name: hpo_terms_mxn_terms fk_terms_mxn_terms_parent_id; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_mxn_terms
    ADD CONSTRAINT fk_terms_mxn_terms_parent_id FOREIGN KEY (parent_id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80296 (class 2606 OID 2367670)
-- Name: hpo_synonyms hpo_synonyms_language_id_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_synonyms
    ADD CONSTRAINT hpo_synonyms_language_id_fkey FOREIGN KEY (language_id) REFERENCES sams_data.languages(id);


--
-- TOC entry 80301 (class 2606 OID 2367675)
-- Name: hpo_terms_otherlanguages hpo_terms_otherlanguages_hpo_id_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_otherlanguages
    ADD CONSTRAINT hpo_terms_otherlanguages_hpo_id_fkey FOREIGN KEY (hpo_id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80302 (class 2606 OID 2367680)
-- Name: hpo_terms_otherlanguages hpo_terms_otherlanguages_language_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_terms_otherlanguages
    ADD CONSTRAINT hpo_terms_otherlanguages_language_fkey FOREIGN KEY (language) REFERENCES sams_data.languages(id);


--
-- TOC entry 80297 (class 2606 OID 2367685)
-- Name: hpo_term_mxn_opposites term_mxn_opposites_id_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_term_mxn_opposites
    ADD CONSTRAINT term_mxn_opposites_id_fkey FOREIGN KEY (id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80298 (class 2606 OID 2367690)
-- Name: hpo_term_mxn_opposites term_mxn_opposites_opposite_id_fkey; Type: FK CONSTRAINT; Schema: sams_data; Owner: sams
--

ALTER TABLE ONLY sams_data.hpo_term_mxn_opposites
    ADD CONSTRAINT term_mxn_opposites_opposite_id_fkey FOREIGN KEY (opposite_id) REFERENCES sams_data.hpo_terms(id);


--
-- TOC entry 80438 (class 0 OID 0)
-- Dependencies: 19
-- Name: SCHEMA sams_data; Type: ACL; Schema: -; Owner: sams
--

GRANT USAGE ON SCHEMA sams_data TO PUBLIC;


--
-- TOC entry 80439 (class 0 OID 0)
-- Dependencies: 13652
-- Name: TABLE hpo_children; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_children TO PUBLIC;


--
-- TOC entry 80440 (class 0 OID 0)
-- Dependencies: 13653
-- Name: TABLE hpo_hpo_mxn_genes; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT ON TABLE sams_data.hpo_hpo_mxn_genes TO PUBLIC;


--
-- TOC entry 80441 (class 0 OID 0)
-- Dependencies: 13654
-- Name: TABLE hpo_hpo_mxn_genes_cumulated; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT ALL ON TABLE sams_data.hpo_hpo_mxn_genes_cumulated TO PUBLIC;


--
-- TOC entry 80442 (class 0 OID 0)
-- Dependencies: 13655
-- Name: TABLE hpo_hpo_mxn_omim; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_hpo_mxn_omim TO PUBLIC;


--
-- TOC entry 80443 (class 0 OID 0)
-- Dependencies: 13657
-- Name: TABLE hpo_parents; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_parents TO PUBLIC;


--
-- TOC entry 80444 (class 0 OID 0)
-- Dependencies: 13659
-- Name: TABLE hpo_synonyms; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_synonyms TO PUBLIC;


--
-- TOC entry 80445 (class 0 OID 0)
-- Dependencies: 13661
-- Name: TABLE hpo_terms; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_terms TO PUBLIC;


--
-- TOC entry 80446 (class 0 OID 0)
-- Dependencies: 13662
-- Name: TABLE hpo_terms_mxn_terms; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE sams_data.hpo_terms_mxn_terms TO PUBLIC;


--
-- TOC entry 80447 (class 0 OID 0)
-- Dependencies: 13665
-- Name: TABLE omim; Type: ACL; Schema: sams_data; Owner: sams
--

GRANT SELECT ON TABLE sams_data.omim TO PUBLIC;


-- Completed on 2022-03-15 13:20:43 CET

--
-- PostgreSQL database dump complete
--

