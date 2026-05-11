-- =============================================
-- OPOSIWORK — Embeddings vectoriales para RAG
-- =============================================
-- Almacena fragmentos de texto con sus embeddings
-- para búsqueda semántica en el chat de IA.
-- Requiere extensión pgvector.

CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS tema_embeddings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tema_id UUID REFERENCES temas(id) ON DELETE CASCADE,
  contenido_id UUID REFERENCES contenido_temas(id) ON DELETE CASCADE,
  fragmento TEXT NOT NULL,
  embedding vector(1536),          -- OpenAI text-embedding-3-small
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tema_embeddings_tema
  ON tema_embeddings(tema_id);

-- Índice IVFFlat para búsqueda aproximada por similitud coseno
CREATE INDEX IF NOT EXISTS idx_tema_embeddings_cosine
  ON tema_embeddings USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- Función para recuperar los fragmentos más similares a un embedding
CREATE OR REPLACE FUNCTION buscar_fragmentos_similares(
  query_embedding vector(1536),
  limite INTEGER DEFAULT 5
) RETURNS TABLE(tema_id UUID, fragmento TEXT, similitud FLOAT) AS $$
  SELECT
    tema_id,
    fragmento,
    1 - (embedding <=> query_embedding) AS similitud
  FROM tema_embeddings
  ORDER BY embedding <=> query_embedding
  LIMIT limite;
$$ LANGUAGE sql STABLE;

ALTER TABLE tema_embeddings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "embeddings_autenticados" ON tema_embeddings
  FOR SELECT USING (auth.role() = 'authenticated');
