module SystemPipeline_test (systemPipelineSpec) where

import Test.Hspec (Spec, describe, it, pendingWith)

systemPipelineSpec :: Spec
systemPipelineSpec =
  describe "System pipeline" $
    it "preprocessor -> lexer -> parser -> AST -> IR -> TD -> Peephole" $
      pendingWith "TODO: добавить интеграционные smoke/e2e сценарии полного конвейера"
