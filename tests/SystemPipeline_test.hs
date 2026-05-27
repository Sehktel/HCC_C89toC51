module SystemPipeline_test (systemPipelineSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)
import TestMatrix (recordPending)

systemPipelineSpec :: Spec
systemPipelineSpec =
  describe "System pipeline" $
    it "preprocessor -> lexer -> parser -> AST -> IR -> TD -> Peephole" $ do
      recordPending "SystemPipeline" "полный конвейер e2e" "—" "TODO: e2e smoke"
      pendingWith "TODO: добавить интеграционные smoke/e2e сценарии полного конвейера"
