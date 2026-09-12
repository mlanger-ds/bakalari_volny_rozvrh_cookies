#  Jak zamezit zobrazovani souhlasu s cookies v modulu Volny rozvrh (napr. na panelu Amos)

Na webovem serveru 
- je potreba doinstalovat **URL Rewrite** doplnek do IIS, popis je v napovede bakalaru, prvni dve vety v [Nastavení přesměrování z HTTP na HTTPS](https://napoveda.bakalari.cz/wa_instal_certifikat_presmer.htm)  
primy odkaz k Microsoftu na [URL Rewrite](https://www.iis.net/downloads/microsoft/url-rewrite) - popis a stazeni
- v konfiguraci IIS je potreba modifikovat soubor web.config v adresari bakaweb  
po sekci `</security>` a pred `</system.webServer>` doplnit obsah dle [web.config.txt](https://github.com/mlanger-ds/bakalari_volny_rozvrh_cookies/blob/main/web.config.txt)
pokud uz nejaka pravidla `<rule>` - `</rule>` obsahuje tak nove pravidlo pridat
- po aktualizaci bakalaru je potreba toto doplneni provest znovu  
  lze pouzit powershell script mod_web_conf_rule.ps1  
  `.\mod_web_conf_rule.ps1 -WebConfigPath 'H:\bakalari\bakaweb\web.config'`  
  co skript zajišťuje
  - vytvoří časově označenou zálohu původního web.config
  - ověří, že XML je platné
  - nevytvoří duplicitní pravidlo
  - zachová již existující pravidla
  - vytvoří `<rewrite>` a `<rules>`, pokud chybějí
  - vloží `<rewrite>` bezprostředně za `<security>`, pokud je nutné sekci vytvořit
  - vloží nové pravidlo na začátek kolekce, aby nebylo předběhnuto obecnějším pravidlem
