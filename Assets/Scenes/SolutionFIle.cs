using Microsoft.Unity.VisualStudio.Editor;

namespace Sample
{
    public static class DotnetProjectUtility
    {
        public static void CreateProject()
        {
            new ProjectGeneration().Sync();
        }
    }
}
