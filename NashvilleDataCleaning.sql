SELECT *
FROM NashvilleHousing;

-- Many values were imported as empty strings (''). It would be best to convert those to NULL

UPDATE
    NashvilleHousing
SET
    LandUse = CASE LandUse WHEN '' THEN NULL ELSE LandUse END,
    PropertyAddress = CASE PropertyAddress WHEN '' THEN NULL ELSE PropertyAddress END,
    SaleDate = CASE SaleDate WHEN '' THEN NULL ELSE SaleDate END,
    SalePrice = CASE SalePrice WHEN '' THEN NULL ELSE SalePrice END,
    LegalReference = CASE LegalReference WHEN '' THEN NULL ELSE LegalReference END,
    SoldAsVacant = CASE SoldAsVacant WHEN '' THEN NULL ELSE SoldAsVacant END,
    OwnerName = CASE OwnerName WHEN '' THEN NULL ELSE OwnerName END,
    OwnerAddress = CASE OwnerAddress WHEN '' THEN NULL ELSE OwnerAddress END,
    Acreage = CASE Acreage WHEN '' THEN NULL ELSE Acreage END,
    TaxDistrict = CASE TaxDistrict WHEN '' THEN NULL ELSE TaxDistrict END,
    LandValue = CASE LandValue WHEN '' THEN NULL ELSE LandValue END,
    BuildingValue = CASE BuildingValue WHEN '' THEN NULL ELSE BuildingValue END,
    TotalValue = CASE TotalValue WHEN '' THEN NULL ELSE TotalValue END,
    YearBuilt = CASE YearBuilt WHEN '' THEN NULL ELSE YearBuilt END,
    Bedrooms = CASE Bedrooms WHEN '' THEN NULL ELSE Bedrooms END,
    FullBath = CASE FullBath WHEN '' THEN NULL ELSE FullBath END,
    HalfBath = CASE HalfBath WHEN '' THEN NULL ELSE HalfBath END;



-- PropertyAddress has 29 NULL values: 

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL;

-- Upon examining the data, we find that separate listings with the same ParcelID have the same PropertyAddress. Thus, we can use the ParcelID to fill in the missing PropertyAddress values:


SELECT a.ParcelID, a.PropertyAddress, a.UniqueID, b.ParcelID, b.PropertyAddress, b.UniqueID, IFNULL(a.PropertyAddress,b.PropertyAddress)
FROM NashvilleHousing as a 
	JOIN NashvilleHousing as b 
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL;



UPDATE NashvilleHousing as a
JOIN NashvilleHousing as b 
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress,b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;


-- Separating the PropertyAddress into separate columns

SELECT PropertyAddress, SUBSTRING_INDEX(PropertyAddress, ',', 1) as Address
, SUBSTRING_INDEX(PropertyAddress, ',', -1) as City
FROM NashvilleHousing;

-- Property Street name and number:

ALTER TABLE NashvilleHousing
ADD PropertyAddressSplit Nvarchar(255);

UPDATE NashvilleHousing
SET PropertyAddressSplit = SUBSTRING_INDEX(PropertyAddress, ',', 1)


-- Property City name:

ALTER TABLE NashvilleHousing
ADD PropertyCity Nvarchar(255); 

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING_INDEX(PropertyAddress, ',', -1)


-- Doing the same to OwnerAddress: 

Select OwnerAddress,
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS OwnerAddressSplit,
	
	SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1) AS OwnerCity,
	
	SUBSTRING_INDEX(OwnerAddress, ',', -1) AS OwnerState
FROM NashvilleHousing;

-- Owner Street name and number:

ALTER TABLE NashvilleHousing
ADD OwnerAddressSplit Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerAddressSplit = SUBSTRING_INDEX(OwnerAddress, ',', 1)

-- Owner City name:

ALTER TABLE NashvilleHousing
ADD OwnerCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', -2), ',', 1)

-- Owner State name:

ALTER TABLE NashvilleHousing
ADD OwnerState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerState = SUBSTRING_INDEX(OwnerAddress, ',', -1)



-- Investigating SoldAsVacant:

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant;

-- It's important that there are only 2 values here, 'Yes' or 'No'. We found 4 distinct values: 'Yes', 'No', 'Y', 'N'. We should change 'Y' and 'N' to 'Yes' and 'No', respectively.

SELECT SoldAsVacant, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
							WHEN SoldAsVacant = 'N' THEN 'No'
							ELSE SoldAsVacant
							END
FROM NashvilleHousing;




UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
							WHEN SoldAsVacant = 'N' THEN 'No'
							ELSE SoldAsVacant
							END;
							
							
							
							
-- Investigate for duplicates:

SELECT ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference, COUNT(*)
FROM NashvilleHousing
GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
HAVING COUNT(*) > 1;


-- Drop Columns that we don't need:

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress,
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress,
DROP COLUMN SaleDate;

SELECT *
FROM NashvilleHousing