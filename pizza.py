import argparse

def parse_cmd_line():
  parser = argparse.ArgumentParser(prog="pizza", usage='%(prog)s -n NUM [-l] [-f] [-nb]', formatter_class=argparse.RawDescriptionHelpFormatter,
    description='''Pizza, Pasta e Mandolino:
    ti permette di calcolare in pochi secondi quanti ingredienti ti occorrono per il tuo impasto.
    Puoi scegliere fra due tipi di ricette a seconda del tipo di lievitazione:
    - Lievitazione lenta in frigo (24 ore)¹:
      25 ore prima: impastare e mettere in una ciotola con coperchio a chiusura
      24 ore prima: porre in frigo la massa
       5 ore prima: estrarre la massa dal frigo, tagliare i panielli (250 g circa) e metterli nelle cassette con coperchio
       0 ore prima: stendere e infornare

    - Lievitazione "veloce" fuori frigo (8 ore)¹:
      9 ore prima: impastare
      8 ore prima: tagliare i panielli (200 g circa) e mettere nelle cassette con coperchio
      0 ore prima: stendere e infornare

¹ La durata delle lievitazione varia a seconda della temperatura a cui viene lasciato l'impasto.
  Temperature basse comportano tempi di lievitazione più lunghi non considetati in questa applicazione.''')
  parser.add_argument('-n', '--num', metavar='NUM', dest='doughsNumber', type=int, required=True, help='Numero di panielli: quante pizze vuoi fare, per esempio metti 3 se vuoi fare 3 pizze. (peso di ogni paniello ~200g)')
  parser.add_argument('-l', '--lievitazione', metavar='8|24 ORE', choices=[8, 24], dest='leaveningHours', type=int, default=8, help='Usa 24 per la ricetta a lievitazione lenta: 19 ore nel frigo e 5 ore fuori. Oppure usa 8 per una lievitazione di 8 ore fuori frigo. Default 8')
  parser.add_argument('-f', '--lievitofresco', dest='isFreshYeast', action='store_true', default=False, help='Usa questo flag se per la tua preparazione userai lievito fresco anziché secco.')
  parser.add_argument('-nb', '--no-bilancia', dest='hasScale', action='store_false', default=True, help='Usa questo flag se non hai una bilancia o non ne vuoi usare una e preparerai il tuo impasto un po\' alla belin di cane')
  parser.add_argument('--version', action='version', version='%(prog)s 2.1')
  return vars(parser.parse_args())

# https://www.ilgiornaledelcibo.it/cambio-tra-volume-e-peso-in-cucina-la-tabella/
# https://blog.giallozafferano.it/allacciateilgrembiule/un-cucchiaio-quanti-gr-sono/
def convert2spoon(what, g):
  return {
    'durumWheatSemolina': g / 22,
    'flour': g / 20,
    'flour0': g / 20,
    'manitoba': g / 25,
    'oil': g / 8,
    'salt': g / 20,
    'sugar': g / 7,
    'water': g / 15,
    'yeast': g / 3,
    'yeastFresh': g / 3
  }[what]

def output(prefix, what, g, has_scale, alternative):
  print(prefix, end="")
  print((' %.2f g' % g) if has_scale else (' ~%.2f %s' % (convert2spoon(what, g), alternative)))

def main():
  # const
  SPOON = 'cucchiai'
  TEASPOON = 'cucchiaini da caffé'
  # https://blog.giallozafferano.it/cookingiulia/2014/09/18/lievito-di-birra/
  yeast_fresh_per_dry = 3.29
  flour_per_dough = 185
  manitoba_perc = 20 / flour_per_dough
  durum_wheat_semolina_perc = 10 / flour_per_dough
  water_perc = 100 / flour_per_dough
  salt_per_liter = 50
  yeast_per_kilo_8 = 300 / flour_per_dough
  yeast_per_kilo_24 = 100 / flour_per_dough

  # read input
  args = parse_cmd_line()
  doughs_num = args['doughsNumber']
  recipe = args['leaveningHours']
  is_fresh_yeast = args['isFreshYeast']
  has_scale = args['hasScale']

  if recipe == 24:
    yeast_per_kilo = yeast_per_kilo_24
  elif recipe == 8:
    yeast_per_kilo = yeast_per_kilo_8
  else:
    print('Possibili valori per l\'argomento --lievitazione sono 8 o 24')
    exit(1)

  flour = flour_per_dough * doughs_num
  manitoba =  manitoba_perc * flour
  durum_wheat_semolina =  durum_wheat_semolina_perc * flour
  flour0 = flour - manitoba - durum_wheat_semolina
  water = flour * water_perc
  salt = salt_per_liter * water / 1000
  oil = salt
  yeast = yeast_per_kilo * flour / 1000
  yeast_fresh = yeast * yeast_fresh_per_dry
  sugar = yeast

  print('Ingredienti per %d panielli con %d ore di lievitazione' % (doughs_num, recipe))
  output(' totale farina:..', 'flour', flour, has_scale, SPOON)
  output('   manitoba:.....', 'manitoba', manitoba, has_scale, SPOON)
  output('   semola:.......', 'durumWheatSemolina', durum_wheat_semolina, has_scale, SPOON)
  output('   farina 0:.....',  'flour0', flour0, has_scale, SPOON)
  output(' acqua:..........', 'water', water, has_scale, SPOON)
  output(' olio:...........',  'oil', oil, has_scale, SPOON)
  output(' sale:...........', 'salt', salt, has_scale, SPOON)
  output(' zucchero:.......',  'sugar', sugar, has_scale, TEASPOON)
  if is_fresh_yeast:
    output(' lievito fresco:.', 'yeastFresh', yeast_fresh, has_scale, TEASPOON)
  else:
    output(' lievito secco:..', 'yeast', yeast, has_scale, TEASPOON)

if __name__ == "__main__":
  main()

# ~@:-]
