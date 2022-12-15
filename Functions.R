library(ggplot2)
# %% [code]
# %% [code]
# Load data in a normalized format
# --------------------------------

# Load Breast Cancer Wisconsin Data and return a data.frame with the data, 
# and a list with keys "outcomes_numeric", "outcomes_categorical", "features_numeric", 
# "features_categorical" holding the relevant variable names.
wisconsin_data <- function(){
    # Read data
    df = read_csv("data.csv")

    # Identify outcomes and features
    variables = list(
        numeric_outcomes = c(),
        categorical_outcomes = c("diagnosis"),
        numeric_features = names(df)[3:(ncol(df)-1)],
        categorical_features = c()
    )
    
    # Keep relevant data only
    df = df[, c(variables$categorical_outcomes, variables$numeric_features)]

    return(list(df=df, variables=variables))
}

# Convenience functions
# ---------------------

#' Plot distribution of all variables in the data grouping by an independent categorical variable.
#'     
#'  Parameters
#'  ----------
#'      data : DataFrame
#'          data table to plot
#'      dv : str
#'          name of dependent categorical variable in `data`
plot_data <- function(data, dv){

    # Check `data` us if type `data.frame`
    if (!is.data.frame(data)){
        stop(paste("`data` must be of type `data.frame`. The passed variable is", class(data), "instead."))
    }
    # Check `dv` is of type `str`
    if (!is.character(dv)){
        stop(paste("`dv` must be of type `character`. The passed variable is", class(dv), "instead."))
    }
    # Check `dv` is an existing column in `data`
    if (!(dv %in% colnames(data))){
        stop("The specified `dv` is not in the `data`.")
    }

    # Get list of columns to plot
    col_types = as.list(sapply(data, class))
    # Check that the dependent variable is categorical
    if (col_types[[dv]] != 'factor'){
        # Raise an error message to help the user understand what's wrong
        stop(paste("The independent variable must be of type factor. The specified column is", col_types[[dv]], "instead."))
    }
    # Remove independent variable from `col_types`, as this will not be separately plotted
    col_types[[dv]] <- NULL

    # Calculate number of rows and columns in the figure
    n = length(col_types)
    nrows = floor(sqrt(n))  # Floor rounding
    ncols = ceiling(n/nrows)  # Ceil rounding
    
    # Allocate a vector to place the results
    plots = vector(length=length(col_types), "list")

    # Plot each columns
    coln = 0
    for (col_name in names(col_types)){  # col_name = names(col_types)[[2]]
        coln = coln + 1
        # Check if the current column (col_n and col_name) is of numeric type
        if (col_types[col_name] == 'numeric'){
          p = ggplot2::ggplot(data, ggplot2::aes_string(x=col_name, color=dv, fill=dv)) +
              ggplot2::geom_histogram(alpha=.5, position="identity", bins=30)
        # Check if the current column (col_n and col_name) is categorical
        } else if (any(col_types[[col_name]] == 'factor')){
            count_data = data %>% group_by_at(c(dv, col_name)) %>% count()
          p = ggplot2::ggplot(count_data, ggplot2::aes_string(x = dv, y = 'n', color = col_name, fill = col_name)) + 
                ggplot2::geom_bar(position = "fill",stat = "identity")
        }
        # Append plot
        plots[[coln]] = p
    }

    # Plot grid
    args = append(plots, list(labels=names(col_types), ncol=ncols, nrow=nrows))
    # labels=labels
    do.call(cowplot::plot_grid, args)
}


# Functions to fit and evaluate a z-normalization process
# -----------------------------------------------------------------

zscore <- function(cols=NULL){
    return(list(mean_ = NULL,
                sd_ = NULL,
                cols = cols))
}

zscore.fit <- function(model, df){
    if (is.null(model$cols)){
        model$cols = names(df)
    }
    model$mean_ = apply(df[, model$cols], 2, mean)
    model$sd_ = apply(df[, model$cols], 2, sd)
    return(model)
}

zscore.eval <- function(model, df){
    return(as.data.frame(t((t(df[, model$cols]) - model$mean_)/model$sd_)))    
}


# Distances
# -----------------------------------------------------------------

#' Euclidean distance between all rows in the matrix X and the row vector x
euclidean_dist <- function(X, x){
    return(sqrt(rowSums(sweep(as.matrix(X), 2, as.matrix(x))^2)))
}

#' Mahalanobis distance between all rows in the matrix X and the row vector x
mahalanobis_dist <- function(X, x){
    return(stats::mahalanobis(x = as.matrix(X), center = as.matrix(x), cov = cov(X)))
}

#' Cosine distance between all rows in the matrix X and the row vector x
cosine_dist <- function(X, x){
    Xm = as.matrix(X)
    xm = as.matrix(x)
    return(1 - pmax((Xm %*% t(xm))/(sqrt(rowSums(Xm^2)) * sqrt(sum(xm^2))), 0))
}

# Artificial Neural Network functions
# -----------------------------------

#' Binary cross-entropy / log loss function
logloss <- function(y, y_){
    E = y*log(y_ + 0.00001) + (1 - y)*log(1 - y_ + 0.00001)
    return(- mean(E))
}
           
#' Derivative of the binary cross-entropy / log loss function
logloss.dE_dy_ <- function(y, y_){
    return((y_ - y) / (y_*(1 - y_)))
}
           
# Activation functions
# --------------------
           
sigmoid <- function(i){
    return(1 / (1 + exp(-i)))
}
          
sigmoid.do_di <- function(i=NULL, o=NULL){
    if (is.null(o)){
        o = sigmoid(i)    
    }
    return(o*(1 - o))
}