-- ## DB settings
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;
COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA public;
COMMENT ON EXTENSION ltree IS 'data type for hierarchical tree-like structures';

SET search_path = public, pg_catalog;

CREATE FUNCTION regexp_match_array(a text[], regexp text) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
select exists (select * from unnest(a) as x where x ~ regexp);
$$;

ALTER FUNCTION public.regexp_match_array(a text[], regexp text) OWNER TO urlcov;
CREATE FUNCTION regexp_not_match_array(a text[], regexp text) RETURNS boolean
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
select exists (select * from unnest(a) as x where x ~ regexp);
$$;

ALTER FUNCTION public.regexp_not_match_array(a text[], regexp text) OWNER TO urlcov;
SET default_tablespace = '';
SET default_with_oids = false;

-- ## DB tables
CREATE TABLE depth_coverage (
    uuid character varying(36),
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    host text,
    path text,
    depth integer,
    path_hash text,
    parent_hash character varying(10),
    listing_uid character varying(15),
    listing_id character varying(50),
    lp_listing_id character varying(50),
    researchers_count bigint,
    alabels_count bigint,
    parameters_count bigint,
    vulnerabilities text,
    hit_count bigint,
    response_code integer,
    processed timestamp with time zone,
    max_depth integer,
    tarantula_count bigint,
    scope_type character varying(10),
    total_children bigint,
    resource_hits bigint,
    is_virtual boolean,
    researchers_sample text,
    alabels_sample text,
    parameters_sample text,
    file_extentions text,
    content_types text,
    tarantula_start timestamp with time zone,
    tarantula_end timestamp with time zone,
    real_hit_count bigint,
    real_parameters_sample text,
    real_alabels_sample text,
    real_researchers_sample text,
    real_alabels_count bigint,
    real_parameters_count bigint,
    real_researchers_count bigint
);
ALTER TABLE depth_coverage OWNER TO urlcov;

CREATE TABLE listing_domains (
    id integer NOT NULL,
    listing_id integer,
    listing_uid character varying(50),
    domain text,
    codename text,
    status text,
    wildcard boolean
);
ALTER TABLE listing_domains OWNER TO urlcov;

CREATE TABLE vulnerability_coverage (
    vulnerability_id character varying(36),
    resolved_at timestamp with time zone,
    host text,
    path text,
    listing_uid character varying(25),
    parent_hash character varying(10),
    path_hash text,
    depth integer,
    max_depth integer,
    processed_at timestamp without time zone,
    is_virtual boolean,
    researcher character varying(30),
    listing_category_id text,
    listing_category_name text,
    vuln_category text,
    cvss_final double precision,
    created_at timestamp with time zone
);
ALTER TABLE vulnerability_coverage OWNER TO urlcov;

CREATE VIEW abhi12s11_ef3d3ffa7b_attack_surface AS
 WITH listing_codename_mapping AS (
         SELECT listing_domains.listing_uid,
            listing_domains.codename
           FROM listing_domains
          GROUP BY listing_domains.listing_uid, listing_domains.codename
        )
 SELECT dc.start_time,
    dc.end_time,
    dc.listing_uid,
    dc.response_code,
    dc.depth,
    dc.path_hash,
    dc.parent_hash,
    dc.host,
    dc.path,
    NULL::text AS vulnerabilities,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN ''::text
            ELSE dc.alabels_sample
        END AS alabels_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.alabels_count
        END AS alabels_count,
    dc.researchers_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.hit_count
        END AS hit_count,
    dc.scope_type,
    dc.processed AS processed_at,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN ''::text
            ELSE dc.real_alabels_sample
        END AS real_alabels_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.real_hit_count
        END AS real_hit_count,
    dc.real_parameters_sample,
    dc.real_researchers_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.real_alabels_count
        END AS real_alabels_count,
    ld.codename
   FROM (depth_coverage dc
     JOIN listing_codename_mapping ld ON (((ld.listing_uid)::text = (dc.listing_uid)::text)))
UNION ALL
 SELECT vc.resolved_at AS start_time,
    vc.resolved_at AS end_time,
    vc.listing_uid,
    200 AS response_code,
    vc.depth,
    vc.path_hash,
    vc.parent_hash,
    vc.host,
    vc.path,
    (((vc.vulnerability_id)::text || ' => '::text) || "substring"((vc.cvss_final)::text, 0, 5)) AS vulnerabilities,
    ''::text AS alabels_sample,
    0 AS alabels_count,
    vc.researcher AS researchers_sample,
    0 AS hit_count,
    'in'::character varying AS scope_type,
    vc.processed_at,
    ''::text AS real_alabels_sample,
    0 AS real_hit_count,
    ''::text AS real_parameters_sample,
    vc.researcher AS real_researchers_sample,
    0 AS real_alabels_count,
    ld.codename
   FROM (vulnerability_coverage vc
     JOIN listing_codename_mapping ld ON (((ld.listing_uid)::text = (vc.listing_uid)::text)))
  WHERE (vc.listing_category_name = 'Web Application'::text);

ALTER TABLE abhi12s11_ef3d3ffa7b_attack_surface OWNER TO urlcov;
COMMENT ON VIEW abhi12s11_ef3d3ffa7b_attack_surface IS '1504228358';

CREATE VIEW abhi12s11_ef3d3ffa7b_listing_uid_codename_mapping AS
 SELECT listing_domains.listing_uid,
    listing_domains.codename
   FROM listing_domains
  GROUP BY listing_domains.listing_uid, listing_domains.codename;

ALTER TABLE abhi12s11_ef3d3ffa7b_listing_uid_codename_mapping OWNER TO urlcov;
COMMENT ON VIEW abhi12s11_ef3d3ffa7b_listing_uid_codename_mapping IS '1502928262';

CREATE VIEW abhi_727afa101f_attack_surface AS
 WITH listing_codename_mapping AS (
         SELECT listing_domains.listing_uid,
            listing_domains.codename
           FROM listing_domains
          GROUP BY listing_domains.listing_uid, listing_domains.codename
        )
 SELECT dc.start_time,
    dc.end_time,
    dc.listing_uid,
    dc.response_code,
    dc.depth,
    dc.path_hash,
    dc.parent_hash,
    dc.host,
    dc.path,
    NULL::text AS vulnerabilities,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN ''::text
            ELSE dc.alabels_sample
        END AS alabels_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.alabels_count
        END AS alabels_count,
    dc.researchers_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.hit_count
        END AS hit_count,
    dc.scope_type,
    dc.processed AS processed_at,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN ''::text
            ELSE dc.real_alabels_sample
        END AS real_alabels_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.real_hit_count
        END AS real_hit_count,
    dc.real_parameters_sample,
    dc.real_researchers_sample,
        CASE
            WHEN (dc.host = 'Other Locations'::text) THEN (0)::bigint
            ELSE dc.real_alabels_count
        END AS real_alabels_count,
    ld.codename
   FROM (depth_coverage dc
     JOIN listing_codename_mapping ld ON (((ld.listing_uid)::text = (dc.listing_uid)::text)))
UNION ALL
 SELECT vc.resolved_at AS start_time,
    vc.resolved_at AS end_time,
    vc.listing_uid,
    200 AS response_code,
    vc.depth,
    vc.path_hash,
    vc.parent_hash,
    vc.host,
    vc.path,
    (((vc.vulnerability_id)::text || ' => '::text) || "substring"((vc.cvss_final)::text, 0, 5)) AS vulnerabilities,
    ''::text AS alabels_sample,
    0 AS alabels_count,
    vc.researcher AS researchers_sample,
    0 AS hit_count,
    'in'::character varying AS scope_type,
    vc.processed_at,
    ''::text AS real_alabels_sample,
    0 AS real_hit_count,
    ''::text AS real_parameters_sample,
    vc.researcher AS real_researchers_sample,
    0 AS real_alabels_count,
    ld.codename
   FROM (vulnerability_coverage vc
     JOIN listing_codename_mapping ld ON (((ld.listing_uid)::text = (vc.listing_uid)::text)))
  WHERE (vc.listing_category_name = 'Web Application'::text);

ALTER TABLE abhi_727afa101f_attack_surface OWNER TO urlcov;
COMMENT ON VIEW abhi_727afa101f_attack_surface IS '1504216808';

CREATE VIEW abhi_727afa101f_listing_uid_codename_mapping AS
 SELECT listing_domains.listing_uid,
    listing_domains.codename
   FROM listing_domains
  GROUP BY listing_domains.listing_uid, listing_domains.codename;

ALTER TABLE abhi_727afa101f_listing_uid_codename_mapping OWNER TO urlcov;
COMMENT ON VIEW abhi_727afa101f_listing_uid_codename_mapping IS '1502925540';

CREATE TABLE aws_url_count_cache (
    hash_code character varying(20),
    url_count integer,
    timeout timestamp without time zone,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()),
    params jsonb,
    approx boolean DEFAULT false
);
ALTER TABLE aws_url_count_cache OWNER TO urlcov;

CREATE SEQUENCE listing_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER TABLE listing_domains_id_seq OWNER TO urlcov;
ALTER SEQUENCE listing_domains_id_seq OWNED BY listing_domains.id;

CREATE TABLE tarantula_coverage (
    uuid character varying(36),
    start_time timestamp with time zone,
    end_time timestamp with time zone,
    hit_count integer,
    host text,
    path text,
    processed timestamp with time zone,
    parent_hash character varying(10),
    max_depth integer,
    depth integer,
    path_hash text,
    listing_uid character varying(15)
);
ALTER TABLE tarantula_coverage OWNER TO urlcov;

CREATE TABLE url_count_cache (
    hash_code character varying(20),
    url_count integer,
    timeout timestamp without time zone,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()),
    params jsonb,
    approx boolean DEFAULT false
);
ALTER TABLE url_count_cache OWNER TO urlcov;

CREATE TABLE uuid_coverage (
    uuid character varying(36),
    uuid_part character varying(36),
    processed timestamp with time zone
);
ALTER TABLE uuid_coverage OWNER TO urlcov;

CREATE TABLE uuid_vuln_map (
    uuid character varying(36),
    path_hash text,
    vulnerability_id character varying(50),
    cvss character varying(50)
);
ALTER TABLE uuid_vuln_map OWNER TO urlcov;

CREATE TABLE vulnerabilities (
    vulnerability_id character varying(50),
    resolved_at timestamp with time zone,
    listing_id integer,
    vulnerability_category character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    patched_at timestamp with time zone,
    accepted boolean,
    cvss_final numeric(4,2),
    title character varying(255),
    state character varying(255),
    listing_uid character varying(255)
);
ALTER TABLE vulnerabilities OWNER TO urlcov;


-- ### default and constraints
ALTER TABLE ONLY listing_domains ALTER COLUMN id SET DEFAULT nextval('listing_domains_id_seq'::regclass);
ALTER TABLE ONLY listing_domains
    ADD CONSTRAINT listing_domains_pkey PRIMARY KEY (id);

ALTER TABLE ONLY url_count_cache
    ADD CONSTRAINT url_count_cache_hash_code_key UNIQUE (hash_code);
CREATE INDEX aws_ucc_hash_code_idx ON aws_url_count_cache USING btree (hash_code);


--
-- Name: dc_listing_uid_host_depth_idx; Type: INDEX; Schema: public; Owner: urlcov
--

CREATE INDEX dc_listing_uid_host_depth_idx ON depth_coverage USING btree (listing_uid, host, depth);
CREATE INDEX dc_listing_uid_parent_hash_host_idx ON depth_coverage USING btree (listing_uid, parent_hash, host);
CREATE INDEX dc_path_hash_casted_ltree_btree_idx ON depth_coverage USING btree (((replace(path_hash, ','::text, '.'::text))::ltree));
CREATE INDEX dc_response_code_idx ON depth_coverage USING btree (response_code) WHERE (response_code < 400);
CREATE INDEX dc_scope_type_idx ON depth_coverage USING btree (scope_type) WHERE ((scope_type)::text = 'in'::text);
CREATE INDEX dc_string_path_hash_idx ON depth_coverage USING btree (path_hash);
CREATE INDEX dc_time_end_brin_idx ON depth_coverage USING brin (end_time);
CREATE INDEX dc_time_inversed_idx ON depth_coverage USING btree (start_time DESC, end_time DESC);

CREATE INDEX ld_domain_idx ON listing_domains USING btree (domain);
CREATE INDEX ld_listing_uid_idx ON listing_domains USING btree (listing_uid);

CREATE INDEX tc_listing_idx ON tarantula_coverage USING btree (listing_uid);
CREATE INDEX tc_string_path_hash_idx ON tarantula_coverage USING btree (path_hash);

CREATE INDEX ucc_hash_code_idx ON url_count_cache USING btree (hash_code);

CREATE INDEX uvm_path_hash_idx ON uuid_vuln_map USING btree (path_hash);
CREATE INDEX uvm_uuid_idx ON uuid_vuln_map USING btree (uuid);
CREATE INDEX uvm_vulnerability_id_idx ON uuid_vuln_map USING btree (vulnerability_id);

CREATE INDEX vc_listing_uid_host_depth_idx ON vulnerability_coverage USING btree (listing_uid, host, depth);
CREATE INDEX vc_path_hash_casted_ltree_btree_idx ON vulnerability_coverage USING btree (((replace(path_hash, ','::text, '.'::text))::ltree));
CREATE INDEX vc_path_hash_casted_ltree_gist_idx ON vulnerability_coverage USING gist (((replace(path_hash, ','::text, '.'::text))::ltree));
CREATE INDEX vc_resolved_at_brin_idx ON vulnerability_coverage USING brin (resolved_at);
CREATE INDEX vc_string_path_hash_idx ON vulnerability_coverage USING btree (path_hash);

CREATE INDEX vulnerability_id_idx ON vulnerabilities USING btree (vulnerability_id, accepted);
