# Period EYWC ------------------------------------------------------------------

fun_EYWC_p <- function(data_p){
  # select year (ideally 2015, if they don't have enough data, put the maximum year)
  length_check <- data_p %>%
    filter(x %out% over50) %>%
    group_by(Year) %>%
    mutate(q1x = as.numeric(as.character(q1x)),
           px = 1 - q1x) %>%
    drop_na(px) %>%
    summarise(length_px = length(px)) %>%
    filter(length_px == 38)
  
  data_maxY <- max(length_check$Year)
  
  if(data_maxY >= 2015){
    data_maxY <- 2015
  } else {
    data_maxY <- data_maxY
  }
  
  # calculate period EYWC 
  data_p <- data_p %>% 
    filter(Year == data_maxY) %>%
    filter(x %out% over50) %>%
    mutate(q1x = as.numeric(as.character(q1x)),
           px = 1 - q1x,
           lx = cumprod(px),
           L0x = as.numeric(as.character(L0x)),
           l0x = as.numeric(as.character(l0x)))
  
  lx_p <- c(1, data_p$lx[-nrow(data_p)])
  
  Lx_p <- c()
  for(i in 1:37){
    # the equation below should be n/2, where n is the number of age range.
    # in this example, we have 1 year age range, so n/2 = 1/2 = 0.5. 
    # Thus, if you have different age range, then you need to change this n/2 correspondingly.
    # Later as well.
    Lx_p[i] <- 0.5 * (lx_p[i] + lx_p[i+1])
  }
  Lx_p[38] <- lx_p[38]
  
  EYWC_p <- round(sum(Lx_p), 2)
  
  return(EYWC_p)
}


# Cohort EYWC ----

fun_EYWC_c <- function(data_p, data_c){
  length_check <- data_p %>%
    filter(x %out% over50) %>%
    group_by(Year) %>%
    mutate(q1x = as.numeric(as.character(q1x)),
           px = 1 - q1x) %>%
    drop_na(px) %>%
    summarise(length_px = length(px)) %>%
    filter(length_px == 38)
  
  data_maxY <- max(length_check$Year)
  
  if(data_maxY >= 2015){
    data_maxY <- 2015
  } else {
    data_maxY <- data_maxY
  }
  
  # select cohort (ideally 1966 (2015 - 49), if they don't have enough data, put the maximum cohort)
  data_maxBC <- data_maxY - 49
  
  # check whether data_maxBC is within the data_c data range
  bc <- unique(data_c$Cohort)
  
  if(data_maxBC %in% bc) {
    
    # calculate period EYWC 
    data_c <- data_c %>% 
      filter(Cohort == data_maxBC) %>%
      filter(x %out% over50) %>%
      mutate(q1x = as.numeric(as.character(q1x)),
             px = 1 - q1x,
             lx = cumprod(px))
    
  } else {
    
    # select birth cohort having full age-range (38)
    length_check_bc <- data_c %>%
      filter(x %out% over50) %>%
      group_by(Cohort) %>%
      mutate(q1x = as.numeric(as.character(q1x)),
             px = 1 - q1x) %>%
      drop_na(px) %>%
      summarise(length_px = length(px)) %>%
      filter(length_px == 38)
    
    data_maxBC <- max(length_check_bc$Cohort)
    
    # calculate period EYWC 
    data_c <- data_c %>% 
      filter(Cohort == data_maxBC) %>%
      filter(x %out% over50) %>%
      mutate(q1x = as.numeric(as.character(q1x)),
             px = 1 - q1x,
             lx = cumprod(px))
  }
  
  lx_c <- c(1, data_c$lx[-nrow(data_c)])
  
  Lx_c <- c()
  for(i in 1:37){
    Lx_c[i] <- 0.5 * (lx_c[i] + lx_c[i+1])
  }
  Lx_c[38] <- lx_c[38]
  
  EYWC_c <- round(sum(Lx_c), 2)
  
  return(EYWC_c)
}

# CALC -------------------------------------------------------------------------
fun_CALC <- function(px, lxLx){
  
  # px matrix to lx
  lx <- apply(px, 2, cumprod)
  lx <- rbind(rep(1, ncol(px)), lx)
  
  # lx to CAL lx
  CALlx <- c()
  for(i in 1:ncol(px)){
    order <- 38:1
    CALlx[i] <- lx[order[i], i]
  }
  
  #CALlx <- apply(px, 2, prod, na.rm = T)
  
  CALlx <- rev(CALlx)
  
  # CAL lx to CAL Lx
  CALLx <- 0.5 * (CALlx[1:37] + CALlx[2:38])
  CALLx <- c(CALLx, CALlx[38])
  
  # CALC
  
  if(lxLx == "Lx"){
    CALC <- round(sum(CALLx), 2)
  } else {
    CALC <- round(0.5 + sum(CALlx[-1]), 2)
  }
  
  return(CALC)
}

# decomposition ----------------------------------------------------------------
# create a diagonal matrix for CALC choosing lx or px
lxpx <- function(data_c, data_p, lxpx){
  
  # target life table function: lx or px
  target <- lxpx
  
  ## Function to create a matrix of lx or px
  widelxpx <- function(data){
    px <- data %>% 
      as.data.frame() %>% 
      #filter(Cohort >= Y1) %>% # select year from the same year
      filter(x %out% over50) %>%              # select age (12- to 49)
      mutate(q1x = as.numeric(as.character(q1x)),
             px = 1 - q1x) %>% 
      select(Cohort, x, px)
    
    # create a matrix of px
    px_wide <- px %>% 
      mutate(px = ifelse(x %in% c("12-", "13", "14", "15") & is.na(px), 1, px)) %>% 
      spread(key = Cohort, value = px) %>%
      select(-x) %>% 
      as.matrix()
    
    lx_wide <- matrix(NA, ncol = ncol(px_wide), nrow = nrow(px_wide))
    lx_wide[1, ] <- 1
    for(i in 1:(nrow(lx_wide)-1)){
      lx_wide[i+1, ] <- lx_wide[i, ] * px_wide[i, ]
    }
    
    colnames(lx_wide) <- colnames(px_wide)
    
    if(target == "lx"){
      outcome <- lx_wide
    } else {
      outcome <- px_wide
    }
    
    return(outcome)
  }
  
  ## For country 1
  lf_c <- widelxpx(data = data_c)
  
  if(any(colnames(lf_c) == "1966")){
    lf_1966 <- lf_c[, "1966"]
  } else {
    lf_1966 <- NA
  }
  
  ## the position of the maximum completed birth cohort
  if(length(lf_1966[!is.na(lf_1966)]) == 38){
    min1 <- which(colnames(lf_c) == "1966")
    
    lf_c <- lf_c[, min1:ncol(lf_c)]
    
    # extract data in a triangle format
    lf_triangle <- c()
    for(k in 1:ncol(lf_c)){
      lf_triangle <- cbind(lf_triangle, c(lf_c[1:(38 - k + 1), k], rep(NA, k - 1)))
    }
    
    colnames(lf_triangle) <- colnames(lf_c)
    
  } else {
    min1 <- lf_c[nrow(lf_c), ]
    min1 <- length(min1[!is.na(min1)])
    
    ## select data from the maximum completed birth cohort
    lf_triangle <- lf_c[, min1:ncol(lf_c)]
  }
  
  
  ### Prepare period data to create hypothetical data
  
  # create Age:Year matrix contains lx or px
  data_select <- function(Pdata, lf_c){
    
    startY <- as.numeric(as.character(colnames(lf_c)))[ncol(lf_c)] + 12
    lastBC <- lf_c[, ncol(lf_c)]
    endY   <- startY + length(lastBC[!is.na(lastBC)]) - 1
    
    px_wide <- Pdata %>%
      as.data.frame() %>% 
      filter(x %out% over50) %>%
      mutate(q1x = as.numeric(as.character(q1x)),
             px = 1 - q1x) %>%
      select(Year, x, px) %>%
      filter(Year >= startY & Year <= endY) %>%
      spread(key = Year, value = px) %>%
      select(-x) %>%
      as.matrix()
    
    lx_wide <- matrix(NA, ncol = ncol(px_wide), nrow = nrow(px_wide))
    lx_wide[1, ] <- 1
    for(i in 1:(nrow(lx_wide)-1)){
      lx_wide[i+1, ] <- lx_wide[i, ] * px_wide[i, ]
    }
    
    colnames(lx_wide) <- colnames(px_wide)
    
    if(target == "lx"){
      outcome <- lx_wide
    } else {
      outcome <- px_wide
    }
    
    return(outcome)
  }
  
  ## Data from country A using period fertility table
  data_p <- data_select(Pdata = data_p, lf_c = lf_triangle)
  
  # make new data strage: hypthetical cohort
  period2cohort <- function(data){
    
    n <- ncol(data)
    
    bc <- c()
    for(i in 2:n){
      row <- c()
      row <- c(data[i, - c(1:(i - 1))], rep(NA, i-1))
      bc  <- rbind(bc, row)
    }
    bc <- rbind(data[1,], bc)
    
    years <- as.numeric(as.character(colnames(bc)))
    colnames(bc) <- years - 12
    rownames(bc) <- NULL
    
    return(bc)
  }
  
  data_hypbc <- period2cohort(data = data_p)
  
  ## combine cohort data and hypothetical data
  data_hypbc <- rbind(data_hypbc, matrix(NA, dim(lf_triangle)[1] - dim(data_hypbc)[1], ncol(data_hypbc)))
  out_lf_c <- cbind(lf_triangle, data_hypbc[, -1])
  
  
  return(out_lf_c)
}

# calculate CALC and decomposition
CALCDecompFunction  <- function(px1, px2, lxLx, Name1, Name2){
  CALClx  <- c()
  CALClx1 <- c()
  CALClx2 <- c()
  PxCh   <- c()
  
  PxCh <- log(px2 / px1)
  PxCh <- ifelse(is.na(PxCh), 0, PxCh)
  colnames(PxCh) <- rownames(PxCh) <- NULL
  # change the order: 1st column (the youngest cohort) -> the last column (the oldest cohort)
  PxCh <- PxCh[, ncol(PxCh):1]
  
  px2CALlx <- function(px){
    # px matrix to lx
    lx <- apply(px, 2, cumprod)
    lx <- rbind(rep(1, ncol(px)), lx)
    
    # lx to CAL lx
    CALlx <- c()
    for(i in 1:ncol(px)){
      order <- 38:1
      CALlx[i] <- lx[order[i], i]
    }
    CALlx <- rev(CALlx)
    
    return(CALlx)
  }
  
  CALClx1 <- px2CALlx(px1)
  CALClx2 <- px2CALlx(px2)
  
  #CALClx1 <- apply(px1, 2, prod, na.rm = T)
  #CALClx2 <- apply(px2, 2, prod, na.rm = T)
  
  CALClx_mid <- t(matrix(rep((CALClx1 + CALClx2)/2, 38), length(CALClx1)))
  
  # calculate CALC
  CALC <- function(lx, type){
    
    # CALC using lx
    CALC_lx <- sum(lx[-1]) + 0.5
    
    # CALC using Lx
    Lx <- (lx[1:37] + lx[2:38]) / 2
    Lx <- c(Lx, lx[38])
    CALC_Lx <- sum(Lx)
    
    out <- ifelse(type == "lx", CALC_lx, CALC_Lx)
    
    return(out)
  }
  
  # final output
  A1 <- CALC(lx = CALClx1, type = lxLx)
  A2 <- CALC(lx = CALClx2, type = lxLx)
  A3 <- A2 - A1
  A4 <- sum(PxCh * CALClx_mid)
  
  
  print(rbind(c(paste("CALC-", Name1), paste("CALC-", Name2), "Diff", "est-Diff"), round(c(A1, A2, A3, A4), 2)))
  return(PxCh * CALClx_mid)
}
