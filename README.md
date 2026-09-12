#  Jak zamezit zobrazovani souhlasu s cookies v modulu Volny rozvrh (napr. na panelu Amos)

Na webovem serveru 
- je potreba doinstalovat **URL Rewrite** doplnek do IIS, popis je v napovede bakalaru, prvni dve vety v [Nastavení přesměrování z HTTP na HTTPS](https://napoveda.bakalari.cz/wa_instal_certifikat_presmer.htm)  
primy odkaz k Microsoftu na [URL Rewrite](https://www.iis.net/downloads/microsoft/url-rewrite) - popis a stazeni
- v konfiguraci IIS je potreba modifikovat soubor web.config v adresari bakaweb  
po sekci `</security>` a pred `</system.webServer>` doplnit obsah dle web.config.txt
pokud uz nejka pravidla `` - `` obsahuje tak nove pravidlo pridat na konec
- po aktualizaci bakalaru je potreba toto doplneni provest znovu
