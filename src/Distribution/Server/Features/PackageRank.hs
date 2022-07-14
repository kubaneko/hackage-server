module Distribution.Server.Features.PackageRank
  ( rankPackage
  ) where

import           Distribution.Package
import           Distribution.PackageDescription
import           Distribution.Server.Features.DownloadCount
import           Distribution.Server.Features.HaskellPlatform
import           Distribution.Server.Features.PreferredVersions
import           Distribution.Server.Features.Upload
import           Distribution.Server.Users.Group
                                                ( queryUserGroups
                                                , size
                                                )
import           Distribution.Types.Version

import           Data.Maybe                     ( isNothing )

data Scorer = Scorer
  { total :: Double
  , score :: Double
  }

add (Scorer a b) (Scorer c d) = Scorer (a + c) (b + d)

rankPackageIO
  :: VersionsFeature
  -> PlatformFeature
  -> DownloadFeature
  -> UploadFeature
  -> PackageDescription
  -> IO Double
rankPackageIO prefferedV platform download upload p = maintNum
 where
  pkgNm :: PackageName
  pkgNm = pkgName $ package p
  -- Number of maintainers
  maintNum :: IO Double
  maintNum = do
    maint <- queryUserGroups [maintainersGroup upload pkgNm]
    return . fromInteger . toInteger $ size maint
  versions = platformVersions platform pkgNm

rankPackagePure p = reverseDeps + usageTrend + docScore + reverseDeps
 where
  reverseDeps  = 1
  dependencies = allBuildDepends p
  usageTrend   = 1
  docScore     = 1
  testsBench   = (bool2Double . hasTests) p + (bool2Double . hasBenchmarks) p
  isApp        = (isNothing . library) p && (not . null . executables) p
  bool2Double :: Bool -> Double
  bool2Double true  = 1
  bool2Double false = 0

rankPackage
  :: VersionsFeature
  -> PlatformFeature
  -> DownloadFeature
  -> UploadFeature
  -> PackageDescription
  -> IO Double
rankPackage versions platform download upload p =
  rankPackageIO versions platform download upload p
    >>= (\x -> return $ x + rankPackagePure p)


