RefreshExplorer() { ; by teadrinker on D437 @ tiny.cc/refreshexplorer
   local Windows := ComObjCreate("Shell.Application").Windows
   Windows.Item(ComObject(0x13, 8)).Refresh()
   for Window in Windows
      if (Window.Name != "Internet Explorer")
         Window.Refresh()
}