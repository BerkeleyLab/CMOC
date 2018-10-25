function octaveplotformat(gca)
set (get (gca, "xlabel"), "fontweight", "bold")
set (get (gca, "ylabel"), "fontweight", "bold")
set (get (gca, "title"), "fontweight", "bold")
set (get (gca, "children"), "linewidth", 2)
set (gca, "linewidth", 1)
endfunction
