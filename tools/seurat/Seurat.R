#' ---
#' title: "Seurat Analysis"
#' author: "Performed using Galaxy"
#' params:
#'     counts: ""
#'     min_cells: ""
#'     min_genes: ""
#'     low_thresholds: ""
#'     high_thresholds: ""
#'     numPCs: ""
#'     resolution: ""
#'     perplexity: ""
#'     min_pct: ""
#'     logfc_threshold: ""
#'     end_step: ""
#'     showcode: ""
#'     warn: ""
#'     varstate: ""
#'     vlnfeat: ""
#'     featplot: ""
#'     PCplots: ""
#'     nmds: ""
#'     heatmaps: ""
#'     norm_out: ""
#'     variable_out: ""
#'     pca_out : ""
#'     clusters_out: ""
#'     markers_out: ""
#' ---

# nolint start
#+ echo=F, warning = F, message=F
options(show.error.messages = F, error = function() {
    cat(geterrmessage(), file = stderr())
    q("no", 1, F)
})
showcode <- as.logical(params$showcode)
warn <- as.logical(params$warn)
varstate <- as.logical(params$varstate)
vlnfeat <- as.logical(params$vlnfeat)
featplot <- as.logical(params$featplot)
pc_plots <- as.logical(params$PCplots)
nmds <- as.logical(params$nmds)
heatmaps <- as.logical(params$heatmaps)
end_step <- as.integer(params$end_step)
norm_out <- as.logical(params$norm_out)
# we need that to not crash Galaxy with an UTF-8 error on German LC settings.
loc <- Sys.setlocale("LC_MESSAGES", "en_US.UTF-8")

#+ echo = F, warning = `warn`, include =`varstate`
min_cells <- as.integer(params$min_cells)
min_genes <- as.integer(params$min_genes)
print(paste0("Minimum cells: ", min_cells))
print(paste0("Minimum features: ", min_genes))
low_thresholds <- as.integer(params$low_thresholds)
high_thresholds <- as.integer(params$high_thresholds)
print(paste0("Umi low threshold: ", low_thresholds))
print(paste0("Umi high threshold: ", high_thresholds))

if (end_step >= 2) {
    variable_out <- as.logical(params$variable_out)
}


if (end_step >= 3) {
    num_pcs <- as.integer(params$numPCs)
    print(paste0("Number of principal components: ", num_pcs))
    pca_out <- as.logical(params$pca_out)
}
if (end_step >= 4) {
    if (params$perplexity == "") {
        perplexity <- -1
        print(paste0("Perplexity: ", perplexity))
    } else {
        perplexity <- as.integer(params$perplexity)
        print(paste0("Perplexity: ", perplexity))
    }
    resolution <- as.double(params$resolution)
    print(paste0("Resolution: ", resolution))
    clusters_out <- as.logical(params$clusters_out)
}
if (end_step >= 5) {
    min_pct <- as.double(params$min_pct)
    logfc_threshold <- as.double(params$logfc_thresh)
    print(paste0("Minimum percent of cells", min_pct))
    print(paste0("Logfold change threshold", logfc_threshold))
    markers_out <- as.logical(params$markers_out)
}


if (showcode == TRUE) print("Read in data, generate inital Seurat object")
#+ echo = `showcode`, warning = `warn`, message = F
counts <- read.delim(params$counts, row.names = 1)
seuset <- Seurat::CreateSeuratObject(counts = counts, min.cells = min_cells, min.features = min_genes)

if (showcode == TRUE && vlnfeat == TRUE) print("Raw data vizualization")
#+ echo = `showcode`, warning = `warn`, include=`vlnfeat`
if (vlnfeat == TRUE) {
    print(Seurat::VlnPlot(object = seuset, features = c("nFeature_RNA", "nCount_RNA")))
    print(Seurat::FeatureScatter(object = seuset, feature1 = "nCount_RNA", feature2 = "nFeature_RNA"))
}

if (showcode == TRUE) print("Filter and normalize for UMI counts")
#+ echo = `showcode`, warning = `warn`
seuset <- subset(seuset, subset = `nCount_RNA` > low_thresholds & `nCount_RNA` < high_thresholds)
seuset <- Seurat::NormalizeData(seuset, normalization.method = "LogNormalize", scale.factor = 10000)
if (norm_out == TRUE) {
    saveRDS(seuset, "norm_out.rds")
}

if (end_step >= 2) {
    #+ echo = FALSE
    if (showcode == TRUE && featplot == TRUE) print("Variable Genes")
    #+ echo = `showcode`, warning = `warn`, include = `featplot`
    seuset <- Seurat::FindVariableFeatures(object = seuset, selection.method = "mvp")
    if (featplot == TRUE) {
        print(Seurat::VariableFeaturePlot(seuset, cols = c("black", "red"), selection.method = "disp"))
    }
    seuset <- Seurat::ScaleData(object = seuset, vars.to.regress = "nCount_RNA")
    if (variable_out == TRUE) {
        saveRDS(seuset, "var_out.rds")
    }
}

if (end_step >= 3) {
    #+ echo = FALSE
    if (showcode == TRUE && pc_plots == TRUE) print("PCA Visualization")
    #+ echo = `showcode`, warning = `warn`, include = `pc_plots`
    seuset <- Seurat::RunPCA(seuset, npcs = num_pcs)
    seuset <- Seurat::JackStraw(seuset, dims = num_pcs, reduction = "pca", num.replicate = 100)
    seuset <- Seurat::ScoreJackStraw(seuset, dims = 1:num_pcs)
    if (pc_plots == TRUE) {
        print(Seurat::VizDimLoadings(seuset, dims = 1:2))
        print(Seurat::DimPlot(seuset, dims = c(1, 2), reduction = "pca"))
        print(Seurat::DimHeatmap(seuset, dims = 1:num_pcs, nfeatures = 30, reduction = "pca"))
        print(Seurat::JackStrawPlot(seuset, dims = 1:num_pcs))
        print(Seurat::ElbowPlot(seuset, ndims = num_pcs, reduction = "pca"))
    }
    if (pca_out == TRUE) {
        saveRDS(seuset, "pca_out.rds")
    }
}

if (end_step >= 4) {
    #+ echo = FALSE
    if (showcode == TRUE && nmds == TRUE) print("tSNE and UMAP")
    #+ echo = `showcode`, warning = `warn`, include = `nmds`
    seuset <- Seurat::FindNeighbors(object = seuset)
    seuset <- Seurat::FindClusters(object = seuset)
    if (perplexity == -1) {
        seuset <- Seurat::RunTSNE(seuset, dims = 1:num_pcs, resolution = resolution)
    } else {
        seuset <- Seurat::RunTSNE(seuset, dims = 1:num_pcs, resolution = resolution, perplexity = perplexity)
    }
    if (nmds == TRUE) {
        print(Seurat::DimPlot(seuset, reduction = "tsne"))
    }
    seuset <- Seurat::RunUMAP(seuset, dims = 1:num_pcs)
    if (nmds == TRUE) {
        print(Seurat::DimPlot(seuset, reduction = "umap"))
    }
    if (clusters_out == TRUE) {
        tsnedata <- Seurat::Embeddings(seuset, reduction = "tsne")
        saveRDS(seuset, "tsne_out.rds")
        umapdata <- Seurat::Embeddings(seuset, reduction = "umap")
        saveRDS(seuset, "umap_out.rds")
    }
}


if (end_step == 5) {
    #+ echo = FALSE
    if (showcode == TRUE && heatmaps == TRUE) print("Marker Genes")
    #+ echo = `showcode`, warning = `warn`, include = `heatmaps`
    markers <- Seurat::FindAllMarkers(seuset, only.pos = TRUE, min.pct = min_pct, logfc.threshold = logfc_threshold)
    top10 <- dplyr::group_by(markers, cluster)
    top10 <- dplyr::top_n(top10, n = 10, wt = avg_log2FC)
    print(top10)
    if (heatmaps == TRUE) {
        print(Seurat::DoHeatmap(seuset, features = top10$gene))
    }
    if (markers_out == TRUE) {
        saveRDS(seuset, "markers_out.rds")
        data.table::fwrite(x = markers, row.names = TRUE, sep = "\t", file = "markers_out.tsv")
    }
}
# nolint end
