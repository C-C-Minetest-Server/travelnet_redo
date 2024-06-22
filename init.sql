CREATE TABLE IF NOT EXISTS travelnet_redo_networks (
    network_id BIGSERIAL PRIMARY KEY,
    network_name VARCHAR(40) NOT NULL,
    network_owner VARCHAR(20) NOT NULL,
    network_always_cache BOOLEAN DEFAULT FALSE,

    CONSTRAINT uq_network UNIQUE(network_name, network_owner)
);

CREATE TABLE IF NOT EXISTS travelnet_redo_travelnets (
    tvnet_pos_hash BIGINT PRIMARY KEY,
    tvnet_display_name VARCHAR(40) NOT NULL,
    tvnet_network_id BIGINT NOT NULL,
    tvnet_sort_key SMALLINT NOT NULL DEFAULT 0,

    CONSTRAINT fk_tvnet_network_id
        FOREIGN KEY (tvnet_network_id) REFERENCES travelnet_redo_networks (network_id)
        ON DELETE CASCADE
);

ALTER TABLE travelnet_redo_travelnets
ADD COLUMN IF NOT EXISTS tvnet_sort_key SMALLINT NOT NULL DEFAULT 0;
