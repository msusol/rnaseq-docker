#### Differential Expression Analysis with DESeq2 ####
# RNA-seq Analysis Tutorial
# This script performs differential expression analysis using DESeq2

#### Loading Required Libraries ####
# Install and load necessary packages for RNA-seq analysis

# Core bioinformatics packages
suppressPackageStartupMessages({
  library("tidyverse")  # Data manipulation and visualization
  library("DESeq2")     # Differential expression analysis
  library("pheatmap")   # Heatmap visualization
  library("RColorBrewer") # Color palettes
  library("ggrepel")    # Text labels in plots
  
  # Enrichment analysis packages
  library("clusterProfiler")  # Functional enrichment analysis
  library("org.Hs.eg.db")     # Human gene annotation database
  library("cowplot")          # Multi-plot layouts
})

#### Step 1: Import DESeq2 Dataset ####
# Load the pre-computed DESeq2 object from nf-core/rnaseq pipeline
# This contains count data, sample metadata, and experimental design

setwd("~/LosusAI/rnaseq-docker")
load("training/results_test/star_salmon/deseq2_qc/deseq2.dds.RData")

#### Step 2: Inspect DESeq2 Object ####
# Examine the structure and contents of the DESeq2 dataset

# View raw counts
head(counts(dds))

# View sample information (colData)
colData(dds)

# View experimental design
design(dds)

#### Step 3: Create Metadata ####
# Reorganize sample metadata for proper analysis
# Extract relevant information from the DESeq2 object

metadata <- DataFrame(
    sample = colData(dds)$sample,
    condition = colData(dds)$Group1,
    replica = colData(dds)$Group2
)

# Ensure metadata rows match column names of count data
rownames(metadata) <- colnames(counts(dds))

# Update DESeq2 object with new metadata
colData(dds) <- metadata

#### Step 4: Validate Sample Matching ####
# Ensure sample names match between metadata and count data

all(colnames(dds$counts) %in% rownames(metadata))  # Should be TRUE
all(colnames(dds$counts) == rownames(metadata))   # Should be TRUE

#### Step 5: Create New DESeq2 Object ####
# Generate a new DESeq2 dataset with proper design formula

dds_new <- DESeqDataSet(dds, design = ~ condition)

# Verify the new object
head(counts(dds_new))
colData(dds_new)
design(dds_new)

#### Step 6: Pre-filtering ####
# Remove genes with very low counts to improve computational efficiency

smallestGroupSize <- 3  # Minimum number of samples
keep <- rowSums(counts(dds_new) >= 10) >= smallestGroupSize
dds_filtered <- dds_new[keep,]

#### Step 7: Run DESeq2 Analysis ####
# Perform differential expression analysis

dds_final <- DESeq(dds_filtered)

# Alternative step-by-step approach (uncomment if needed):
# dds_final <- estimateSizeFactors(dds_filtered)
# dds_final <- estimateDispersions(dds_final)
# dds_final <- nbinomWaldTest(dds_final)

#### Step 8: Data Transformation for Visualization ####
# Transform counts for QC plots (not used for DE testing)
# Use regularized log transformation (rlog)

rld <- rlog(dds_final, blind = TRUE)

#### Step 9: Quality Control - PCA Plot ####
# Principal Component Analysis to assess sample relationships

pca_plot <- plotPCA(rld, intgroup = "condition")
ggsave("de_results/pca_plot.png", plot = pca_plot, width = 6, height = 5, dpi = 300)

#### Step 10: Quality Control - Sample Distance Heatmap ####
# Hierarchical clustering to check sample similarities

sampleDists <- dist(t(assay(rld)))
sampleDistMatrix <- as.matrix(sampleDists)
rownames(sampleDistMatrix) <- paste(rld$condition, rld$replica, sep = "_")
colnames(sampleDistMatrix) <- paste(rld$condition, rld$replica, sep = "_")

colors <- colorRampPalette(rev(brewer.pal(9, "Greens")))(255)

clustering_plot <- pheatmap(sampleDistMatrix,
                           clustering_distance_rows = sampleDists,
                           clustering_distance_cols = sampleDists,
                           col = colors,
                           fontsize_col = 8,
                           fontsize_row = 8)

ggsave("de_results/clustering_plot.png", plot = clustering_plot, width = 6, height = 5, dpi = 300)

#### Step 11: Extract Normalized Counts ####
# Get normalized count data for downstream analysis

normalized_counts <- as_tibble(counts(dds_final, normalized = TRUE))
normalized_counts$gene <- rownames(counts(dds_final))
normalized_counts <- normalized_counts %>%
  relocate(gene, .before = 1)

write.csv(normalized_counts, file = "de_results/normalized_counts.csv")

#### Step 12: Extract Differential Expression Results ####
# Get results of the DE analysis

res <- results(dds_final)
head(res)
summary(res)
resultsNames(dds_final)

# Prepare results for visualization
res_viz <- res
res_viz$gene <- rownames(res)
res_viz <- as_tibble(res_viz) %>%
  relocate(gene, .before = baseMean)

write.csv(res_viz, file = "de_results/de_result_table.csv")

#### Step 13: Identify Significant DE Genes ####
# Filter for statistically significant differentially expressed genes

resSig <- subset(res_viz, padj < 0.05 & abs(log2FoldChange) > 1)
resSig <- as_tibble(resSig) %>%
  relocate(gene, .before = baseMean)
resSig <- resSig[order(resSig$padj),]

write.csv(resSig, file = "de_results/sig_de_genes.csv")

#### Step 14: MA Plot ####
# Visualize relationship between mean expression and fold change

png("de_results/MA_plot.png", width = 1500, height = 1000, res = 300)
plotMA(res, ylim = c(-2, 2))
dev.off()

#### Step 15: Plot Counts for Specific Gene ####
# Visualize expression of a single gene across conditions

png("de_results/plotCounts.png", width = 1000, height = 1200, res = 300)
plotCounts(dds_final, gene = "ENSG00000142192")  # Example gene
dev.off()

#### Step 16: Heatmap of Significant Genes ####
# Visualize expression patterns of DE genes

significant_genes <- resSig[, 1]

significant_counts <- inner_join(
  normalized_counts,
  significant_genes,
  by = "gene"
) %>%
  column_to_rownames("gene")

heatmap <- pheatmap(significant_counts,
                   cluster_rows = TRUE,
                   fontsize = 8,
                   scale = "row",
                   fontsize_row = 8,
                   height = 10)

ggsave("de_results/heatmap.png", plot = heatmap, width = 6, height = 5, dpi = 300)

#### Step 17: Volcano Plot ####
# Visualize fold change vs statistical significance

res_tb <- as_tibble(res) %>%
  mutate(diffexpressed = case_when(
    log2FoldChange > 1 & padj < 0.05 ~ 'upregulated',
    log2FoldChange < -1 & padj < 0.05 ~ 'downregulated',
    TRUE ~ 'not_de'))

res_tb$gene <- rownames(res)
res_tb <- res_tb %>% relocate(gene, .before = baseMean)

res_tb <- res_tb %>% arrange(padj) %>% mutate(genelabels = "")
res_tb$genelabels[1:5] <- res_tb$gene[1:5]  # Label top 5 genes

volcano_plot <- ggplot(data = res_tb, aes(x = log2FoldChange, y = -log10(padj), col = diffexpressed)) +
  geom_point(size = 0.6) +
  geom_text_repel(aes(label = genelabels), size = 2.5, max.overlaps = Inf) +
  ggtitle("DE genes treatment versus control") +
  geom_vline(xintercept = c(-1, 1), col = "black", linetype = 'dashed', linewidth = 0.2) +
  geom_hline(yintercept = -log10(0.05), col = "black", linetype = 'dashed', linewidth = 0.2) +
  theme(plot.title = element_text(size = rel(1.25), hjust = 0.5),
        axis.title = element_text(size = rel(1))) +
  scale_color_manual(values = c("upregulated" = "red",
                               "downregulated" = "blue",
                               "not_de" = "grey")) +
  labs(color = 'DE genes') +
  xlim(-3,5)

ggsave("de_results/volcano_plot.png", plot = volcano_plot, width = 6, height = 5, dpi = 300)

#### Step 18: Functional Enrichment Analysis ####
# Perform Gene Ontology enrichment analysis

# Prepare gene list for enrichment
gene_list <- res$log2FoldChange
names(gene_list) <- res$gene
gene_list <- sort(gene_list, decreasing = TRUE)

# Get significant genes
res_genes <- resSig$gene

# Run GO enrichment analysis
go_enrich <- enrichGO(
  gene = res_genes,
  universe = names(gene_list),
  OrgDb = org.Hs.eg.db,
  keyType = 'ENSEMBL',
  readable = TRUE,
  ont = "ALL",
  pvalueCutoff = 0.05,
  qvalueCutoff = 0.10
)

# Create visualization plots
barplot <- barplot(go_enrich, title = "Enrichment analysis barplot", font.size = 8)
dotplot <- dotplot(go_enrich, title = "Enrichment analysis dotplot", font.size = 8)
go_plot <- plot_grid(barplot, dotplot, ncol = 2)

ggsave("de_results/go_plot.png", plot = go_plot, width = 13, height = 6, dpi = 300)

#### Analysis Complete ####
# Check the de_results folder for all output files:
# - pca_plot.png
# - clustering_plot.png
# - normalized_counts.csv
# - de_result_table.csv
# - sig_de_genes.csv
# - MA_plot.png
# - plotCounts.png
# - heatmap.png
# - volcano_plot.png
# - go_plot.png

print("Differential expression analysis completed!")
print("Results saved in de_results/ folder")
