-- export PGPASSWORD=8~JbCxfhOtyO6TQpBUmYSxYR && psql -h 10.150.15.150 -U urlcov
alias proddb="export PGPASSWORD=8~JbCxfhOtyO6TQpBUmYSxYR && echo db_host=10.150.0.6 && psql -h 10.150.0.6 -U urlcov"


-- staging
-- CREATE USER urlcov WITH PASSWORD 'Hw-wu3Fe';
-- ALTER DATABASE urlcov OWNER TO urlcov;
-- export PGPASSWORD=Hw-wu3Fe && psql -h 10.128.0.4 -d urlcov -U postgres
-- export PGPASSWORD=Hw-wu3Fe && psql -h 10.128.0.4 -d urlcov -U urlcov
-- ## export PGPASSWORD=Hw-wu3Fe && psql -h 10.128.0.4 -U urlcov

-- export PGPASSWORD=8~JbCxfhOtyO6TQpBUmYSxYR && psql -h localhost -d urlcov -U urlcov

-- export PGPASSWORD=8~JbCxfhOtyO6TQpBUmYSxYR
-- nohup psql -h 10.150.15.150 -U urlcov -f pg_indexex.sql
-- select count(1) from url_count_cache;

-- DROP VIEW abhi12s11_ef3d3ffa7b_attack_surface;
-- DROP VIEW abhi_727afa101f_attack_surface;
-- DROP VIEW prod_nuldt2taratwwgkafjwwo7k_35a39b819f_attack_surface;

-- DROP INDEX dc_listing_uid_host_depth_idx;
-- DROP INDEX dc_listing_uid_parent_hash_host_idx;
-- DROP INDEX dc_path_hash_casted_ltree_btree_idx;
-- DROP INDEX dc_response_code_idx;
-- DROP INDEX dc_scope_type_idx;
-- DROP INDEX dc_string_path_hash_idx;
-- DROP INDEX dc_time_end_brin_idx;
-- DROP INDEX dc_time_inversed_idx;


-- ALTER TABLE depth_coverage RENAME TO depth_coverage_20170902;
-- ALTER TABLE depth_coverage RENAME TO depth_coverage_20170914;
-- DROP TABLE depth_coverage;
-- CREATE TABLE depth_coverage (
--     uuid character varying(36),
--     start_time timestamp with time zone,
--     end_time timestamp with time zone,
--     host text,
--     path text,
--     depth integer,
--     path_hash text,
--     parent_hash character varying(10),
--     listing_uid character varying(15),
--     listing_id character varying(50),
--     lp_listing_id character varying(50),
--     researchers_count bigint,
--     alabels_count bigint,
--     parameters_count bigint,
--     vulnerabilities text,
--     hit_count bigint,
--     response_code integer,
--     processed timestamp with time zone,
--     max_depth integer,
--     tarantula_count bigint,
--     scope_type character varying(10),
--     total_children bigint,
--     resource_hits bigint,
--     is_virtual boolean,
--     researchers_sample text,
--     alabels_sample text,
--     parameters_sample text,
--     file_extentions text,
--     content_types text,
--     tarantula_start timestamp with time zone,
--     tarantula_end timestamp with time zone,
--     real_hit_count bigint,
--     real_parameters_sample text,
--     real_alabels_sample text,
--     real_researchers_sample text,
--     real_alabels_count bigint,
--     real_parameters_count bigint,
--     real_researchers_count bigint
-- );
-- ALTER TABLE depth_coverage OWNER TO urlcov;

TRUNCATE TABLE listing_domains;

TRUNCATE TABLE depth_coverage;
DROP INDEX dc_listing_uid_host_depth_idx;
DROP INDEX dc_path_hash_casted_ltree_btree_idx;
DROP INDEX dc_response_code_idx;
DROP INDEX dc_string_path_hash_idx;
DROP INDEX dc_time_inversed_idx;

CREATE INDEX  ON depth_coverage USING btree (listing_uid, host, depth);
CREATE INDEX  ON depth_coverage USING btree (((replace(path_hash, ','::text, '.'::text))::ltree));
CREATE INDEX  ON depth_coverage USING btree (response_code) WHERE (response_code < 400);
CREATE INDEX  ON depth_coverage USING btree (path_hash);
CREATE INDEX  ON depth_coverage USING btree (start_time DESC, end_time DESC);
-- CREATE INDEX dc_listing_uid_host_time_idx ON depth_coverage USING btree (listing_uid, host, start_time DESC, end_time DESC);
-- ALTER TABLE depth_coverage CLUSTER ON dc_listing_uid_host_time_idx;

TRUNCATE TABLE url_count_cache;
ALTER TABLE ONLY url_count_cache
    DROP CONSTRAINT url_count_cache_hash_code_key;
DROP INDEX ucc_hash_code_idx;

-- DROP TABLE url_count_cache;
-- ALTER TABLE url_count_cache_gcp RENAME TO url_count_cache;
--
-- CREATE TABLE url_count_cache (
--     hash_code character varying(20),
--     url_count integer,
--     timeout timestamp without time zone,
--     created_at timestamp without time zone DEFAULT timezone('utc'::text, now()),
--     params jsonb,
--     approx boolean DEFAULT false
-- );
-- ALTER TABLE url_count_cache OWNER TO urlcov;
ALTER TABLE ONLY url_count_cache
    ADD CONSTRAINT url_count_cache_hash_code_key UNIQUE (hash_code);
CREATE INDEX ucc_hash_code_idx ON url_count_cache USING btree (hash_code);

-- table row count
SELECT relname as tablename, n_live_tup as rowcount
  FROM pg_stat_user_tables
    ORDER BY n_live_tup DESC;
SELECT pg_xact_commit_timestamp(xmin), * FROM  url_count_cache;
-- check indexing, or cancel it
select tablename, indexname
    from pg_indexes
        where schemaname = 'public'
            and (
                tablename = 'depth_coverage'
                or tablename = 'url_count_cache'
            )
    order by tablename, indexname;

select datname, pid, query_start, trim(substring(query, 1, 128)) as query
    from pg_stat_activity
        where length(query) > 0
            and state <> 'idle'
        and query not like 'select datname, pid, query_start%';

select pg_cancel_backend(2185);
