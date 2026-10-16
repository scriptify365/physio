# Aplikacja dla fizjoterapeuty i klienta: założenia i plan wykonania

Wersja dokumentu: 1.0  
Data: 15.10.2026  
Status: propozycja zakresu i architektury do rozpoczęcia projektu  
Nazwa robocza projektu: PhysioPlan

## 1. Co budujemy

Aplikację, w której fizjoterapeuta tworzy bibliotekę ćwiczeń z filmami i opisami, układa indywidualny plan oraz przypisuje go klientowi. Klient otwiera plan na telefonie, wykonuje trening, oznacza jego realizację i przekazuje feedback. Fizjoterapeuta przegląda wykonanie i na tej podstawie samodzielnie aktualizuje zalecenia.

W dokumencie słowa „klient” i „pacjent” oznaczają użytkownika wykonującego ćwiczenia. W interfejsie należy konsekwentnie używać jednego określenia, ustalonego z fizjoterapeutą.

### Rekomendowany start

Pierwsza wersja powinna być responsywną aplikacją webową z możliwością instalacji jako PWA. Fizjoterapeuta korzysta głównie z komputera, a klient z telefonu. To ten sam produkt i ta sama baza danych, z różnymi widokami zależnymi od uprawnień.

PWA to aplikacja otwierana przez adres internetowy, którą można dodać do ekranu głównego telefonu. Nie wymaga publikacji w sklepach, aby rozpocząć pilotaż. Sposób instalowania zależy od urządzenia i przeglądarki; Apple opisuje taki tryb również dla iPhone'a. [S1][S2]

Rekomendowany stos: **Vue 3 + TypeScript + ASP.NET Core + PostgreSQL + prywatny magazyn wideo**. Wykorzystuje Twoje dotychczasowe doświadczenie z Vue i backendem .NET. Nauka Swift, Kotlin albo Flutter nie jest potrzebna do pierwszej wersji.

Jeżeli po pilotażu okaże się potrzebna aplikacja w Google Play lub App Store, kolejnym krokiem może być Capacitor i wykorzystanie istniejącego interfejsu Vue. Capacitor obsługuje dołączenie do istniejącego projektu webowego, ale wersja mobilna nadal wymaga osobnego przygotowania, testów i publikacji. [S3]

## 2. Co wynika z pomysłu, a co proponuje ten dokument

### Potwierdzony zakres

1. Fizjoterapeuta dodaje ćwiczenia w formie wideo i opisu.
2. Klient widzi na telefonie, co ma wykonać.
3. Klient może oznaczyć wykonanie całego treningu.
4. Klient może przekazać feedback.
5. Projekt powinien być wykonalny dla osoby bez doświadczenia w tworzeniu aplikacji mobilnych.

### Robocze założenia do pierwszej wersji

| Obszar | Proponowane założenie |
| :-- | :-- |
| Odbiorcy | Jeden gabinet, początkowo 1–2 fizjoterapeutów |
| Pilotaż | 10–20 pełnoletnich klientów przez 4 tygodnie |
| Język | Polski interfejs; kod i nazwy techniczne po angielsku |
| Urządzenia | Telefon klienta; komputer i telefon fizjoterapeuty |
| Dostęp | Konta klientów tworzone przez zaproszenia |
| Model biznesowy | Narzędzie do pracy gabinetu; bez płatności w aplikacji |
| Organizacja treningów | Jeden obowiązujący plan i maksymalnie jeden zaplanowany trening na dzień |
| Harmonogram | Konkretne dni tygodnia oraz data początku i końca planu |
| Internet | Wymagany do pobierania danych, filmów i zapisywania wyników |
| Treści | Własne materiały fizjoterapeuty lub materiały z odpowiednimi prawami |
| Ocena ćwiczeń | Fizjoterapeuta dobiera ćwiczenia i zmienia zalecenia |
| Dane | Tylko dane potrzebne do planu i informacji zwrotnej |

Są to propozycje projektowe. Przed implementacją należy zatwierdzić je w krótkim przeglądzie z fizjoterapeutą. Zmiana tych założeń może zmienić zakres i czas pracy.

## 3. Cel pierwszej wersji i sposób sprawdzenia pomysłu

Pierwsza wersja ma odpowiedzieć na trzy pytania:

1. Czy klient rozumie plan i potrafi wykonać trening bez dodatkowego tłumaczenia obsługi aplikacji?
2. Czy fizjoterapeuta szybciej przekazuje zalecenia i łatwiej przegląda ich realizację?
3. Czy feedback pomaga w rozmowie z klientem i aktualizacji planu?

Proponowane cele pilotażu, będące hipotezami do sprawdzenia:

| Wskaźnik | Cel roboczy | Sposób pomiaru |
| :-- | :-- | :-- |
| Aktywacja | Minimum 80% zaproszonych klientów uruchamia konto w ciągu 7 dni | Zaproszenie i pierwsze poprawne logowanie |
| Samodzielna obsługa | Minimum 90% uczestników potrafi otworzyć film i zapisać wynik bez pomocy | Krótki test obserwowany |
| Przygotowanie planu | Mediana poniżej 5 minut przy gotowej bibliotece ćwiczeń | Pomiar kilku rzeczywistych zadań |
| Trwałość zapisu | Brak utraconych potwierdzonych zapisów i podwójnych treningów | Testy oraz zgłoszenia z pilotażu |
| Przydatność | Większość uczestników chce korzystać dalej | Rozmowa po 2 i 4 tygodniach |

Deklaracja wykonania treningu jest informacją podaną przez klienta. Obejrzenie filmu nie potwierdza wykonania ćwiczenia. Sam wskaźnik realizacji nie dowodzi poprawy stanu zdrowia.

## 4. Role i uprawnienia

| Rola | Dostęp w pierwszej wersji |
| :-- | :-- |
| Klient | Własny plan, własne treningi, własny feedback i ustawienia konta |
| Fizjoterapeuta | Biblioteka gabinetu, szablony oraz dane przypisanych mu klientów |
| Właściciel gabinetu | Zarządzanie kontami personelu i przypisaniami klientów; dostęp kliniczny tylko przy odpowiednim uprawnieniu |
| Administrator techniczny | Utrzymanie systemu; bez domyślnego wglądu w treść danych zdrowotnych |

Jedna osoba może pełnić kilka ról, ale uprawnienia należy nadawać jawnie. Utworzenie konta administratora technicznego nie powinno automatycznie nadawać dostępu fizjoterapeuty.

W pilotażu interfejs obsługuje jeden gabinet. Rekordy biznesowe od początku mają `ClinicId`, a dostęp do klienta wynika z przypisania do opiekuna. Nie budujemy jeszcze sprzedaży abonamentów ani samoobsługowego zakładania wielu gabinetów.

## 5. Zakres MVP

MVP oznacza najmniejszą wersję, którą można bezpiecznie oddać rzeczywistym użytkownikom. Poniższe funkcje są wymagane do pilotażu.

| ID | Funkcja | Kiedy jest gotowa |
| :-- | :-- | :-- |
| F01 | Konta i logowanie | Działa zaproszenie, ustawienie hasła, logowanie, wylogowanie i reset hasła |
| F02 | Lista klientów | Fizjoterapeuta widzi swoich klientów i może otworzyć ich profil |
| F03 | Biblioteka ćwiczeń | Można dodać, wyszukać, edytować i zarchiwizować ćwiczenie |
| F04 | Filmy | Można bezpiecznie wgrać i odtworzyć obsługiwany film na telefonie |
| F05 | Szablony treningów | Można zapisać zestaw ćwiczeń i ponownie użyć go przy układaniu planu |
| F06 | Indywidualny plan | Można ustawić parametry ćwiczeń, dni treningowe i okres obowiązywania |
| F07 | Publikacja i historia zaleceń | Klient widzi opublikowany plan; późniejsza edycja nie zmienia historii |
| F08 | Widok treningu na telefonie | Klient widzi ćwiczenia w kolejności, opis, film i parametry wykonania |
| F09 | Realizacja treningu | Klient zapisuje wykonanie całości, części albo pominięcie treningu |
| F10 | Feedback | Klient dodaje ocenę trudności, opcjonalną ocenę bólu i komentarz |
| F11 | Podgląd dla fizjoterapeuty | Widoczna jest historia treningów i lista nieprzejrzanego feedbacku |
| F12 | Obsługa i ochrona danych | Działają ograniczenia dostępu, logi zdarzeń, kopie i procedury obsługi danych |
| F13 | Wygoda na telefonie | Interfejs jest responsywny, a instalacja PWA i sytuacje utraty połączenia są sprawdzone |

### Poza MVP

1. Czat, wideokonsultacje i komunikacja w czasie rzeczywistym.
2. Płatności, faktury, subskrypcje i rezerwacja wizyt.
3. AI dobierające ćwiczenia lub interpretujące dolegliwości.
4. Analiza ruchu z kamery i automatyczna ocena techniki.
5. Filmy przesyłane przez klientów i dokumentacja obrazowa pacjenta.
6. Pełna dokumentacja medyczna, integracje z systemami gabinetowymi i EDM.
7. Integracje z zegarkami, Apple Health i Health Connect.
8. Pełne działanie offline, pobieranie filmów i synchronizacja konfliktów.
9. Aplikacje sklepowe, powiadomienia push i konta osób niepełnoletnich.
10. Rozbudowana grywalizacja i rankingi.

Każda nowa funkcja powinna rozwiązywać problem potwierdzony w pilotażu. Najpierw trzeba domknąć proces od przypisania planu do przeglądu feedbacku.

## 6. Główny proces fizjoterapeuty

1. Loguje się do panelu.
2. Dodaje do biblioteki ćwiczenie z opisem i filmem.
3. Zaprasza klienta na wskazany adres e-mail.
4. Układa plan od zera albo kopiuje gotowy szablon.
5. Dla każdego ćwiczenia ustawia parametry i ewentualną indywidualną uwagę.
6. Wybiera dni treningowe oraz okres obowiązywania planu.
7. Sprawdza podgląd z perspektywy klienta i publikuje plan.
8. Przegląda wykonanie oraz nowy feedback.
9. W razie potrzeby publikuje nową wersję zaleceń.

Przykład organizacji: plan na 4 tygodnie, zestaw A w poniedziałek i piątek, zestaw B w środę. Każdy zestaw zawiera kilka ćwiczeń. To przykład działania harmonogramu, a nie gotowe zalecenie terapeutyczne.

## 7. Główny proces klienta

1. Otwiera zaproszenie i zakłada hasło do swojego konta.
2. Po zalogowaniu trafia na ekran „Dzisiaj”.
3. Widzi nazwę zestawu, listę ćwiczeń i zalecenia fizjoterapeuty.
4. Otwiera ćwiczenie, odtwarza film i czyta parametry.
5. Przechodzi przez trening we własnym tempie.
6. Wybiera „Wykonano całość”, „Wykonano część” albo „Pomijam trening”.
7. Może uzupełnić krótki feedback i zapisuje wynik.
8. Widzi potwierdzenie zapisu oraz historię swoich treningów.

Oznaczenie całego treningu jednym działaniem jest dostępne od początku. Nie wymagamy klikania każdej serii ani odtwarzania filmu do końca. Przy wykonaniu częściowym klient wskazuje wykonane ćwiczenia lub opisuje, co udało się zrobić. Nie mierzymy dokładnej liczby faktycznie wykonanych powtórzeń w MVP.

Feedback jest opcjonalny. Jego pominięcie nie blokuje zapisania realizacji treningu.

## 8. Ćwiczenie i indywidualne parametry

### Ćwiczenie w bibliotece

| Pole | Założenie |
| :-- | :-- |
| Nazwa | Krótka i zrozumiała dla klienta |
| Opis wykonania | Pozycja wyjściowa, przebieg ruchu i zakończenie |
| Film | Jedno główne nagranie pokazujące ćwiczenie |
| Miniatura | Obraz startowy filmu |
| Sprzęt | Na przykład mata albo guma; pole opcjonalne |
| Tagi | Obszar ciała, typ ruchu lub inne kategorie ustalone przez gabinet |
| Uwagi | Wskazówki i częste błędy opisane przez fizjoterapeutę |
| Status | Aktywne albo zarchiwizowane |

W MVP treść opisu to zwykły tekst lub ograniczony format tekstowy. Nie pozwalamy na wklejanie dowolnego HTML.

### Parametry w planie konkretnego klienta

1. Liczba serii.
2. Liczba powtórzeń albo czas jednej serii w sekundach.
3. Strona: lewa, prawa, obie albo nie dotyczy.
4. Przerwa pomiędzy seriami.
5. Indywidualna uwaga, na przykład sposób ustawienia lub zakres ruchu.
6. Kolejność ćwiczenia w zestawie.

Parametry należą do planu klienta. Zmiana liczby powtórzeń u jednego klienta nie zmienia biblioteki ani planów pozostałych osób.

Walidacja sprawdza poprawność danych, na przykład dodatnią liczbę serii i poprawną jednostkę czasu. Aplikacja nie wyznacza automatycznie terapeutycznie właściwego obciążenia.

## 9. Zasady planów, harmonogramu i historii

### Biblioteka, szablon i plan to różne rzeczy

1. **Biblioteka ćwiczeń** zawiera materiały wielokrotnego użytku.
2. **Szablon treningu** jest gotowym zestawem do skopiowania.
3. **Plan klienta** zawiera jego własne zalecenia i harmonogram.
4. **Wersja planu** utrwala opublikowaną treść zaleceń.
5. **Trening w konkretnym dniu** odwołuje się do właściwej wersji planu.

Skopiowanie szablonu tworzy niezależny plan. Późniejsze zmiany szablonu nie aktualizują automatycznie planów klientów.

### Publikacja i zmiany

1. Fizjoterapeuta edytuje wersję roboczą, której klient nie widzi.
2. Publikacja wymaga co najmniej jednego kompletnego ćwiczenia i gotowych filmów.
3. Przy publikacji zapisywana jest niezmienna wersja: teksty, kolejność, parametry oraz identyfikatory konkretnych plików wideo.
4. Zmiana opublikowanego planu tworzy nową wersję. Domyślnie zaczyna obowiązywać od następnego dnia.
5. Nowa wersja może zmienić przyszłe, nierozpoczęte treningi. Nie zmienia treningów rozpoczętych, zakończonych ani historycznych.
6. Zmiana treści w bibliotece nie podmienia opisów ani filmu w opublikowanych wersjach.
7. Stare nagranie pozostaje dostępne zgodnie z ustaloną retencją, jeżeli odwołuje się do niego zachowana historia.
8. Pilna zmiana zaleceń odbywa się przez wstrzymanie planu i kontakt fizjoterapeuty z klientem. MVP nie podmienia po cichu rozpoczętego treningu.

W historii musi dać się ustalić, jakie zalecenia klient widział w konkretnym dniu.

### Harmonogram

1. Plan ma datę początku, datę końca, dni tygodnia i zestaw przypisany do każdego dnia treningowego.
2. Roboczy limit długości jednego planu to 12 tygodni. Dłuższą współpracę obsługuje się kolejnymi planami.
3. Dla jednego klienta dopuszczamy maksymalnie jeden zaplanowany trening dziennie.
4. Zaplanowane treningi na cały okres powstają podczas publikacji. Przy tym limicie nie jest potrzebny rozbudowany generator harmonogramu.
5. Gdy zmienia się przyszły harmonogram, zachowujemy istniejący identyfikator treningu dla tej samej daty, a wycofane terminy oznaczamy jako anulowane. Operacja jest zapisywana w audycie.
6. Wstrzymanie planu anuluje przyszłe, nierozpoczęte terminy. Nie oznacza ich jako niewykonane.
7. Dzień bez zaplanowanego treningu pokazuje informację o braku zadania, a nie zaległość.
8. Nie pozwalamy opublikować nakładających się aktywnych planów dla tego samego klienta.

Daty treningów zapisujemy jako daty lokalne, a czas zdarzeń jako UTC. Plan posiada strefę czasową, domyślnie `Europe/Warsaw`. Zmiana czasu letniego nie może przenosić treningu na inny dzień. W pilotażu podróż klienta nie zmienia automatycznie strefy jego planu.

### Statusy i późniejsze oznaczanie

Statusy zapisywane w systemie: `scheduled`, `in_progress`, `completed`, `partial`, `skipped`, `cancelled`.

1. Brak wyniku po zakończeniu zaplanowanego dnia jest wyświetlany jako brak potwierdzenia wykonania. Nie zakładamy, że klient na pewno nie ćwiczył.
2. Klient może później uzupełnić wynik minionego treningu w okresie swojego dostępu do historii. System zachowuje pierwotny termin i rzeczywisty czas zgłoszenia.
3. Spóźnione zgłoszenie jest widoczne jako zgłoszone po terminie.
4. Klient może poprawić omyłkowy wynik. Zachowujemy ślad zmiany i czas ostatniej aktualizacji.
5. Ponowione żądanie po błędzie sieci nie tworzy nowego treningu ani drugiego feedbacku.
6. Zakończony plan jest dostępny w historii do czasu upływu uzgodnionej retencji lub ograniczenia dostępu.

## 10. Feedback i podgląd realizacji

### Formularz po treningu

| Pole | Zakres |
| :-- | :-- |
| Realizacja | Całość, część albo pominięcie |
| Wykonane ćwiczenia | Opcjonalne przy częściowym wykonaniu |
| Trudność | Za łatwo, odpowiednio, za trudno; opcjonalne |
| Ból lub dyskomfort po treningu | Opcjonalna subiektywna skala 0–10; 0 oznacza brak, 10 największy możliwy |
| Komentarz | Opcjonalny, do 1000 znaków |

Ocena bólu ma stale takie samo pytanie i opis skali. Brak odpowiedzi jest pustą wartością, a nie wynikiem 0. Nie porównujemy nieporównywalnych pytań, na przykład bólu w spoczynku z bólem podczas ćwiczenia.

Fizjoterapeuta widzi datę treningu, wynik, feedback i czas jego zgłoszenia. Może oznaczyć feedback jako przejrzany. Oznaczenie nie usuwa treści.

W MVP nie ma automatycznej interpretacji bólu ani automatycznej zmiany planu. Klient widzi informację, kiedy fizjoterapeuta przegląda wpisy i jak skontaktować się z gabinetem. Formularz nie jest kanałem natychmiastowej pomocy.

### Proste zestawienie

1. Liczba treningów zakończonych w całości.
2. Liczba treningów wykonanych częściowo.
3. Liczba pominiętych treningów.
4. Liczba terminów bez potwierdzenia.
5. Lista najnowszego, nieprzejrzanego feedbacku.

Wskaźnik pełnej realizacji liczymy jako liczbę treningów zakończonych w całości podzieloną przez liczbę nieanulowanych treningów zaplanowanych do końca danego dnia w wybranym okresie. Obok pokazujemy liczby, na przykład „3 z 4”, i osobno wykonanie częściowe. Dla zera zaplanowanych treningów pokazujemy brak danych. Nie wliczamy przyszłych terminów.

## 11. Ekrany i wygoda użytkowania

### Klient

| Ekran | Najważniejsza zawartość |
| :-- | :-- |
| Dzisiaj | Dzisiejszy trening, jego stan i przycisk otwarcia |
| Trening | Kolejność ćwiczeń, parametry i przejście do filmu |
| Ćwiczenie | Film, opis i indywidualne zalecenie |
| Podsumowanie | Realizacja i opcjonalny feedback |
| Plan | Najbliższe terminy i okres obowiązywania |
| Historia | Poprzednie treningi i własne odpowiedzi |
| Konto | Hasło, wylogowanie, prywatność i kontakt do gabinetu |

### Fizjoterapeuta

| Ekran | Najważniejsza zawartość |
| :-- | :-- |
| Pulpit | Nowy feedback i klienci wymagający przeglądu |
| Klienci | Wyszukiwanie, zaproszenie, przypisanie opiekuna |
| Profil klienta | Aktywny plan, historia i feedback |
| Biblioteka | Filmy, opisy, tagi i archiwizacja |
| Szablony | Zapisane zestawy do ponownego użycia |
| Edytor planu | Ćwiczenia, parametry, harmonogram i publikacja |
| Ustawienia | Personel, kontakt, dostęp i obsługa danych |

### Zasady interfejsu

1. Najważniejsze działanie na ekranie jest widoczne bez szukania w menu.
2. Duże przyciski, czytelny tekst, dobry kontrast i obsługa powiększenia.
3. Wszystkie działania mają etykiety tekstowe; stan nie jest przekazywany wyłącznie kolorem.
4. Opis pozwala zrozumieć ćwiczenie także bez dźwięku. Istotne instrukcje z nagrania znajdują się również w tekście.
5. Film uruchamia się po działaniu klienta i może być odtwarzany na pełnym ekranie.
6. Zmianę kolejności ćwiczeń można wykonać także przyciskami, bez przeciągania.
7. Błąd pokazuje, co się stało i co użytkownik może zrobić dalej.
8. Potwierdzenie zapisu pojawia się dopiero po odpowiedzi serwera.
9. Na ekranie bez planu klient otrzymuje jasną informację i kontakt do gabinetu.
10. Przy wygasłej sesji aplikacja prosi o ponowne logowanie i nie pokazuje danych poprzedniego użytkownika.

## 12. Technologia i architektura

### Wybór technologii

| Element | Rekomendacja | Powód |
| :-- | :-- | :-- |
| Interfejs | Vue 3 + TypeScript + Vite | Możliwość wykorzystania dotychczasowych umiejętności |
| Nawigacja i stan | Vue Router; Pinia tylko dla wspólnego stanu | Prosta obsługa widoków i sesji |
| Komponenty | Jedna biblioteka komponentów, roboczo Vuetify | Spójne formularze, tabele i widoki responsywne |
| Backend | ASP.NET Core na .NET 10 LTS | Znany ekosystem i wersja z długim wsparciem [S4] |
| Konta | ASP.NET Core Identity | Gotowe mechanizmy haseł, resetowania i MFA |
| Baza | PostgreSQL + Entity Framework Core | Relacje między klientami, planami, treningami i historią |
| Wideo | Prywatny Azure Blob Storage | Oddzielenie plików od bazy i ograniczanie dostępu |
| Hosting | Azure App Service na Linuxie | Jeden serwis aplikacji, bez własnego utrzymywania serwera |
| Baza produkcyjna | Zarządzany PostgreSQL w UE | Kopie i utrzymanie jako usługa; konfigurację trzeba wycenić |
| Sekrety | Managed Identity i Azure Key Vault tam, gdzie potrzebne | Ograniczenie sekretów w konfiguracji aplikacji |
| CI/CD | Azure DevOps | Wykorzystanie doświadczenia z pipeline'ami |
| Późniejsza aplikacja sklepowa | Capacitor | Możliwość ponownego wykorzystania Vue [S3] |

Wersje bibliotek frontendowych dobieramy z aktualnie wspieranych stabilnych wydań przy rozpoczęciu implementacji i utrwalamy w pliku zależności. Nie opieramy projektu na wydaniach eksperymentalnych.

### Prosty podział odpowiedzialności

1. Interfejs Vue wyświetla dane i obsługuje formularze.
2. API sprawdza konto, gabinet, przypisanie klienta i reguły biznesowe.
3. PostgreSQL przechowuje konta, opisy, plany, treningi i feedback.
4. Magazyn plików przechowuje filmy oraz miniatury.
5. Dostawca poczty wysyła zaproszenia i wiadomości do odzyskiwania dostępu.

Na start wybieramy **modularny monolit**: jeden backend podzielony na moduły. Nie są potrzebne mikroserwisy, Kubernetes ani osobny system komunikatów.

Frontend i API publikujemy pod tym samym adresem, na przykład interfejs pod `/`, a API pod `/api`. ASP.NET Core może udostępniać zbudowane pliki Vue. Upraszcza to wdrożenie i obsługę sesji.

Repozytorium powinno zawierać frontend, backend, testy i dokumentację. Zalecany podział katalogów: `frontend`, `backend`, `tests`, `docs`, `infra`. Moduły backendu: `Identity`, `Patients`, `Exercises`, `Plans`, `Sessions`, `Media`, `Audit`.

Nie współdzielimy firmowych kont, danych, sekretów ani infrastruktury z prywatnym projektem.

## 13. Najważniejsze dane

To model pojęciowy do zaprojektowania bazy, a nie ostateczna lista tabel. Tabele techniczne Identity i tabele łącznikowe powstaną podczas implementacji.

| Encja | Najważniejsze dane i cel |
| :-- | :-- |
| `User` | Tożsamość użytkownika, e-mail, stan konta; mechanizmy Identity |
| `Clinic` | Nazwa gabinetu, kontakt i strefa domyślna |
| `ClinicMembership` | Powiązanie konta z gabinetem i rolą |
| `PatientProfile` | Profil klienta w konkretnym gabinecie i stan współpracy |
| `CareAssignment` | Powiązanie klienta z fizjoterapeutą i okres dostępu |
| `Invitation` | Odbiorca, zakres zaproszenia, skrót tokenu, termin ważności i wykorzystanie |
| `Exercise` | Aktualna treść ćwiczenia w bibliotece i jego status |
| `VideoAsset` | Niepubliczny klucz pliku, format, rozmiar, długość i stan przetwarzania |
| `WorkoutTemplate` | Edytowalny zestaw ćwiczeń do ponownego użycia |
| `PatientPlan` | Klient, okres planu i stan publikacji lub wstrzymania |
| `PatientPlanVersion` | Niezmienna opublikowana treść i harmonogram, numer wersji, autor i data |
| `PlanExercise` | Kopia treści ćwiczenia, parametry, kolejność, zestaw i stały identyfikator filmu |
| `TrainingSession` | Klient, data lokalna, wersja planu, zestaw, stan i czasy zdarzeń |
| `SessionFeedback` | Jedna bieżąca odpowiedź do treningu, jej wersja i informacja o przejrzeniu |
| `AuditEvent` | Kto, kiedy i jaką operację wykonał; bez kopiowania całej treści zdrowotnej |

### Reguły integralności

1. `ClinicId` w żądaniu nie jest dowodem uprawnienia. Serwer ustala dozwolony zakres na podstawie zalogowanego konta.
2. Wszystkie odwołania muszą prowadzić do rekordów tego samego gabinetu.
3. Nie może istnieć więcej niż jeden nieanulowany trening klienta na tę samą datę lokalną.
4. Feedback ma unikalne powiązanie z treningiem. Kolejny zapis aktualizuje odpowiedź z zachowaniem audytu.
5. Publikacja planu i utworzenie terminów odbywają się atomowo, w transakcji.
6. Aktualizacje korzystają z kontroli wersji rekordu, aby jedna karta przeglądarki nie nadpisywała po cichu drugiej.
7. Archiwizacja ćwiczenia blokuje jego nowe użycia, ale nie usuwa odniesień historycznych.
8. Usuwanie danych nie jest kaskadowym kasowaniem całej historii bez sprawdzenia retencji i zależności.

## 14. Główne operacje API

API opisujemy w OpenAPI. Role oraz dostęp do konkretnego rekordu sprawdzamy na serwerze przy każdej operacji, także przy pobieraniu filmu.

| Obszar | Przykładowe operacje |
| :-- | :-- |
| Sesja | `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/auth/me` |
| Odzyskiwanie konta | `POST /api/auth/forgot-password`, `POST /api/auth/reset-password` |
| Klienci | `GET /api/patients`, `POST /api/invitations`, `GET /api/patients/{id}` |
| Przyjęcie zaproszenia | `POST /api/invitations/accept` |
| Ćwiczenia | `GET /api/exercises`, `POST /api/exercises`, `PATCH /api/exercises/{id}` |
| Wideo | `POST /api/media/uploads`, `POST /api/media/{id}/finalize`, `GET /api/media/{id}/playback` |
| Szablony | `GET /api/workout-templates`, `POST /api/workout-templates` |
| Plan | `POST /api/patients/{id}/plans`, `PATCH /api/plans/{id}/draft`, `POST /api/plans/{id}/publish` |
| Plan klienta | `GET /api/me/plan`, `GET /api/me/sessions` |
| Wynik treningu | `PUT /api/me/sessions/{id}/result` |
| Feedback dla opiekuna | `GET /api/patients/{id}/feedback`, `POST /api/feedback/{id}/review` |

To przykładowy kontrakt funkcjonalny, nie wymóg ręcznego pisania każdego endpointu. Konta powinny korzystać z mechanizmów Identity, z własnymi ograniczeniami zaproszeń i uprawnień.

Do zapisu wyniku używamy stałego identyfikatora treningu, kontroli wersji i klucza powtórzenia żądania. Lista klientów i biblioteka mają stronicowanie. Błędy nie ujawniają danych innego klienta, stosu wyjątków ani konfiguracji serwera.

## 15. Filmy: zapis, odtwarzanie i ograniczenia

### Wariant na początek

MVP przyjmuje przygotowane pliki MP4 z obrazem H.264 i ewentualnym dźwiękiem AAC. Roboczo ograniczamy film do 2 minut i 50 MB. Preferowane są krótkie demonstracje w rozdzielczości 720p. Ostateczny limit ustalamy na podstawie jakości i próby na telefonach.

Samo rozszerzenie `.mp4` nie gwarantuje obsługi. Telefon może zapisać film w innym kodeku lub w kontenerze MOV. W pierwszym prototypie trzeba wgrać rzeczywiste nagrania z telefonu fizjoterapeuty i sprawdzić całą drogę.

Przed pilotażem wybieramy jeden zamknięty wariant:

1. Fizjoterapeuta akceptuje przygotowywanie filmów w uzgodnionym formacie i otrzymuje krótką instrukcję eksportu.
2. Jeżeli konieczne jest wrzucanie oryginalnych nagrań z telefonu, dodajemy automatyczne przetwarzanie MOV/HEVC do formatu odtwarzanego przez aplikację. To osobne zadanie, którego nie obejmuje podstawowy szacunek czasu.

Nie obiecujemy obsługi dowolnego filmu przed wdrożeniem i sprawdzeniem przetwarzania.

### Przepływ pliku

1. Fizjoterapeuta wybiera film, a serwer sprawdza jego uprawnienia i limit.
2. Serwer przyznaje czasowy dostęp do przesłania jednego nowego pliku o losowym kluczu.
3. Przesyłanie odbywa się do prywatnego obszaru plików oczekujących na zatwierdzenie.
4. Backend sprawdza rzeczywisty rozmiar, format, długość i możliwość odczytu nagrania. Sama deklaracja przeglądarki nie wystarcza.
5. Powstaje miniatura; film otrzymuje stan `ready` albo `rejected`. Do tego momentu nie można opublikować go klientowi.
6. Odtwarzanie wymaga sprawdzenia, czy klient ma dostęp do planu używającego tego konkretnego filmu.
7. Serwer wydaje krótko ważny adres tylko do odczytu konkretnego obiektu. Dla Azure preferowany jest user delegation SAS. [S6]

Proces finalizacji jest ponawialny. Przerwane transfery i nieprzypisane pliki są okresowo usuwane według ustalonego limitu czasu.

### Zasady techniczne

1. Baza przechowuje metadane i identyfikatory obiektów, a pliki pozostają w magazynie obiektowym.
2. Filmy i miniatury nie są anonimowo publiczne.
3. Adres odtwarzania jest ważny krótko, roboczo 10–15 minut. Aplikacja potrafi odnowić go po ponownej autoryzacji.
4. Odebranie uprawnienia blokuje wydanie następnego adresu. Już wydany adres może działać do wygaśnięcia; pilne unieważnienie wymaga osobnej procedury.
5. Prywatny magazyn oznacza brak anonimowego dostępu. Nie zakładamy sieciowego Private Endpoint dostępnego bezpośrednio z telefonu klienta.
6. Nie nadpisujemy pliku używanego przez opublikowany plan. Nowe nagranie ma nowy identyfikator.
7. Odtwarzacz obsługuje przewijanie i żądania zakresowe. Nagranie jest przygotowane do rozpoczęcia odtwarzania bez pobierania całości.
8. Nie zapisujemy podpisanych adresów w logach, analityce ani zewnętrznych narzędziach.
9. Narzędzia do analizy filmu uruchamiamy z ograniczeniami czasu, pamięci i uprawnień.
10. Przy większym ruchu można dodać adaptacyjne strumieniowanie i CDN z odpowiednią kontrolą dostępu. Nie jest to warunek pierwszego pilotażu.

Ograniczenie dostępu do filmu nie uniemożliwia nagrania ekranu przez uprawnionego odbiorcę. Produkt nie obiecuje pełnej ochrony przed kopiowaniem.

## 16. Konta i bezpieczeństwo

### Logowanie

1. Dla PWA wybieramy ASP.NET Core Identity i sesję opartą na bezpiecznym ciasteczku. Microsoft rekomenduje ciasteczka dla aplikacji przeglądarkowych. [S5]
2. Ciasteczko sesji ma `HttpOnly`, `Secure` i odpowiednie `SameSite`.
3. Żądania zmieniające dane mają ochronę CSRF; samo `SameSite` nie jest jedynym zabezpieczeniem. [S7]
4. Nie przechowujemy tokenów uwierzytelnienia w `localStorage`.
5. Wymagamy MFA dla personelu mającego dostęp do danych klientów i dla administratorów. Dla klientów jest opcjonalne w pierwszej wersji.
6. Reset hasła i przyjęcie zaproszenia wykorzystują tokeny o ograniczonej ważności. Zaproszenie jest jednorazowe i nie przyznaje innej roli niż określona przez uprawnionego nadawcę.
7. Rejestracja personelu nie jest publiczna. Ukrycie przycisku rejestracji nie wystarcza; backend także blokuje nieuprawnione tworzenie kont i ról.
8. Działają limity prób logowania, resetowania hasła, przyjmowania zaproszeń i wysyłania wiadomości.
9. Zawieszenie konta unieważnia sesje i blokuje nowe żądania, a nie tylko następne logowanie.
10. Klucze ASP.NET Core Data Protection są trwale przechowywane i chronione; wdrożenie nowej wersji nie może przypadkowo utracić kluczy sesji i tokenów.

### Ochrona danych aplikacji

1. HTTPS we wszystkich środowiskach z rzeczywistymi danymi.
2. Sprawdzenie uprawnień do obiektu na backendzie, również przy znanym UUID.
3. Minimalne uprawnienia połączeń do bazy i magazynu; sekrety poza repozytorium.
4. Wrażliwe odpowiedzi API mają `Cache-Control: no-store` i nie trafiają do współdzielonego cache.
5. Logi nie zawierają haseł, tokenów, podpisanych linków ani treści feedbacku.
6. Zdarzenia publikacji planu, zmiany opiekuna, eksportu i zmiany dostępu są audytowane.
7. Narzędzia analityczne i nagrywanie sesji użytkownika nie otrzymują treści ekranów klienta.
8. Środowisko testowe korzysta z danych fikcyjnych.
9. Zmiana opiekuna odbiera dotychczasowy dostęp zgodnie z regułami gabinetu, zamiast pozostawiać go bezterminowo.
10. Zależności są aktualizowane, a publiczne endpointy mają kontrolę wielkości żądań i limitów transferu.

## 17. Dane zdrowotne i ustalenia przed pilotażem

Oceny bólu, opisy dolegliwości i kontekst planu fizjoterapeutycznego mogą stanowić dane dotyczące zdrowia. Projekt traktuje je jako dane szczególnej kategorii. Podstawa z art. 6 RODO i odpowiednia przesłanka z art. 9 wymagają ustalenia dla konkretnego modelu usługi; jeden ogólny checkbox zgody nie rozwiązuje tego automatycznie. [S8][S9]

Przed pilotażem ustalamy z gabinetem oraz osobą odpowiedzialną za ochronę danych:

1. Administratora danych, role dostawców i wymagane umowy powierzenia.
2. Zakres informacji dla klienta i sposób obsługi jego żądań.
3. Okresy przechowywania kont, planów, feedbacku, audytu i kopii.
4. Czy dane stanowią część dokumentacji medycznej oraz jakie szczególne obowiązki wtedy występują.
5. Zasady eksportu, ograniczenia dostępu, usunięcia lub dalszego przechowywania. Usunięcie konta nie oznacza automatycznie usunięcia wszystkiego.
6. Potrzebę oceny skutków dla ochrony danych i postępowanie przy naruszeniu.
7. Regiony przetwarzania oraz podwykonawców, także dla poczty, logów i wsparcia. Sam wybór regionu UE nie kończy analizy transferów.

Minimalizacja: w MVP nie zbieramy PESEL, adresu zamieszkania, dokumentów, zdjęć ani pełnej historii choroby. Uczestniczą dorośli. [S10]

Osobno opisujemy przeznaczenie produktu i weryfikujemy jego kwalifikację regulacyjną. Sam brak AI nie przesądza o wyłączeniu z przepisów o wyrobach medycznych; znaczenie mają funkcje i deklarowane przeznaczenie. MVP ograniczamy do przekazania zaleceń i zebrania deklaracji, bez automatycznych decyzji terapeutycznych. [S11]

## 18. PWA, brak internetu i późniejsza aplikacja mobilna

### Pierwsza wersja

1. Klient może korzystać z linku bez instalowania aplikacji.
2. Można dodać aplikację do ekranu głównego obsługiwanego telefonu.
3. Ekran pomocy pokazuje instrukcję odpowiednią dla urządzenia.
4. Service worker zapisuje tylko statyczne zasoby interfejsu i ekran braku połączenia.
5. Plany, dane klientów, feedback i filmy nie są zapisywane przez service workera do trwałego cache offline.
6. Przy braku internetu nie pokazujemy fikcyjnego potwierdzenia zapisu.
7. Niezapisany formularz pozostaje w pamięci bieżącego widoku; aplikacja informuje, że odświeżenie lub zamknięcie może go utracić. MVP nie obiecuje synchronizacji offline.
8. Po ponownym połączeniu zapis można ponowić bez utworzenia duplikatu.
9. Stan rozpoczętego treningu zapisany na serwerze można odtworzyć po ponownym otwarciu aplikacji.
10. Aktualizacja interfejsu nie odświeża samoczynnie ekranu w trakcie treningu. Wylogowanie czyści stan użytkownika w aplikacji.

Powiadomienia push są osobną funkcją. Ich dostępność i warunki różnią się między platformami, więc pierwszy pilotaż nie może od nich zależeć.

### Kiedy przejść do sklepów

Po pilotażu, jeżeli pojawi się konkretny wymóg: łatwiejsza dystrybucja, określona funkcja urządzenia lub potrzeba uzasadniona przez klientów.

Capacitor pozwala wykorzystać interfejs webowy. Należy jednak zaplanować nowe prace nad logowaniem w środowisku mobilnym, bezpiecznym przechowywaniem poświadczeń, linkami otwierającymi aplikację, uprawnieniami urządzenia i aktualizacjami. Dla natywnego logowania należy dobrać obsługiwane rozwiązanie OIDC z PKCE i logowaniem w przeglądarce systemowej; ASP.NET Core Identity samo w sobie nie jest pełnym serwerem OIDC.

Lokalne budowanie aplikacji iOS wymaga macOS i Xcode; dostępne są też usługi budowania w chmurze. Do testów nadal potrzebny jest rzeczywisty iPhone. [S12] Publikacja w sklepach ma własne wymagania i nie jest automatycznym skutkiem użycia Capacitor.

## 19. Wdrożenie i utrzymanie

### Środowiska

1. **Lokalne:** programowanie, fikcyjni klienci i kilka testowych filmów.
2. **Testowe:** sprawdzenie wdrożenia i działania na telefonach, nadal bez danych pacjentów.
3. **Produkcyjne:** rzeczywiste konta, odseparowana konfiguracja i ograniczony dostęp administracyjny.

Na początku lokalnie można użyć kontenerów PostgreSQL i emulatora magazynu plików. Przed pilotażem trzeba sprawdzić filmy i podpisane linki także na docelowym magazynie, a nie tylko na emulatorze.

### Pipeline

1. Odtworzenie zależności z plików blokujących wersje.
2. Kontrola typów i zbudowanie Vue.
3. Zbudowanie backendu i uruchomienie uzgodnionych testów.
4. Utworzenie jednego wersjonowanego artefaktu aplikacji.
5. Wdrożenie na środowisko testowe i podstawowe sprawdzenie działania.
6. Wdrożenie tej samej wersji na produkcję po ocenie gotowości.

Migracje bazy mają osobny, kontrolowany krok. Zmiana schematu powinna być zgodna z poprzednią wersją aplikacji, jeżeli planujemy prosty powrót do niej. Cofnięcie kodu nie oznacza automatycznego cofnięcia migracji.

### Kopie i monitoring

1. Codzienne kopie bazy oraz odpowiednia ochrona plików przed przypadkowym usunięciem.
2. Test przywrócenia bazy, metadanych plików i wymaganych kluczy przed pilotażem.
3. Robocze cele: utrata maksymalnie 24 godzin danych i odtworzenie w ciągu 8 godzin. To cele projektu do zweryfikowania próbą, a nie deklaracja gwarantowanej dostępności.
4. Monitoring błędów logowania, błędów API, niedostępności bazy i nieudanych transferów.
5. Alerty kosztowe, limit wielkości plików i sprzątanie niedokończonych transferów.
6. Lista osób odpowiedzialnych za zgłoszenia i krótka instrukcja postępowania przy awarii.

Wiadomości e-mail nie zawierają opisów dolegliwości ani feedbacku. Nie dodajemy przypomnień o treningach do MVP; zaproszenia i reset hasła muszą jednak działać od początku. Dostawcę poczty dobieramy przed implementacją tych funkcji i sprawdzamy dostarczalność.

## 20. Koszty i ograniczenia budżetu

Nie podajemy niezweryfikowanej stałej ceny utrzymania. Przed wyborem planów usług trzeba przygotować wycenę konkretnego regionu, konfiguracji, kopii i transferu, na przykład w kalkulatorze Azure. [S13]

| Pozycja | Co trzeba wycenić |
| :-- | :-- |
| Aplikacja | Hosting środowiska produkcyjnego i testowego |
| Baza | Instancja, miejsce, kopie i odtwarzanie |
| Filmy | Materiały źródłowe, wersje opublikowane i miniatury |
| Transfer | Odtwarzanie filmów, w tym ponowne oglądanie |
| Poczta | Zaproszenia, potwierdzenia i resetowanie hasła |
| Pozostałe | Domena, monitoring, sekrety i ewentualne przetwarzanie filmów |
| Prace poza kodem | Nagrania, opisy, testy z użytkownikami i ustalenia prawne |

Przykład obliczenia transferu, będący założeniem projektowym: 50 klientów × 12 treningów miesięcznie × 5 odtworzeń filmu × średnio 8 MB = około 24 GB miesięcznie. Dwukrotne oglądanie daje około 48 GB. Faktyczny wynik zależy od kompresji, przewijania i ponownych pobrań.

Biblioteka 100 filmów po 8 MB zajmuje około 0,8 GB, ale trzeba doliczyć oryginały, starsze wersje i kopie. Te liczby nie są cenami usług.

Przed uruchomieniem zapisujemy zaakceptowany miesięczny budżet, próg alarmowy i osobę kontrolującą koszty. Jeżeli wycena go przekracza, upraszczamy konfigurację lub porównujemy inne usługi zarządzane przed związaniem z nimi implementacji.

## 21. Plan wykonania etap po etapie

Szacunki poniżej są własną prognozą dla jednej osoby znającej podstawy Vue i .NET, uczącej się specyfiki telefonu oraz produkcyjnego wdrożenia. Nie obejmują nagrywania biblioteki, oczekiwania na decyzje, zewnętrznych konsultacji ani wersji sklepowych.

| Etap | Zadania | Warunek ukończenia | Szacunek |
| :-- | :-- | :-- | :-- |
| 0. Doprecyzowanie | Rozmowa z fizjoterapeutą, zakres, szkice głównych ekranów, próbne filmy i wybór formatu | Zatwierdzony scenariusz oraz lista funkcji MVP | 8–12 h |
| 1. Pierwszy działający przekrój | Repozytorium, baza, podstawowy backend, widok Vue, jeden film, jeden trening i zapis wyniku na fikcyjnym koncie | Cały prosty proces działa na telefonie | 16–24 h |
| 2. Konta i dostęp | Identity, zaproszenia, reset hasła, MFA personelu, gabinet i przypisania klientów | Dwa konta klientów nie mają dostępu do cudzych danych | 24–36 h |
| 3. Biblioteka i wideo | Formularze ćwiczeń, prywatny upload, walidacja, miniatury i odtwarzanie | Fizjoterapeuta dodaje materiał, a uprawniony klient odtwarza go na dwóch platformach | 20–32 h |
| 4. Plany i harmonogram | Szablony, parametry, wersje, publikacja i terminy | Plan na kilka tygodni ma poprawną historię i nie tworzy duplikatów | 28–44 h |
| 5. Proces klienta i feedback | Ekran dzisiejszy, trening, wyniki, feedback, historia i przegląd przez opiekuna | Działa pełny scenariusz na danych testowych | 24–36 h |
| 6. PWA i wygoda | Instalacja, czytelność, stany błędów, utrata połączenia, aktualizacja aplikacji | Scenariusz działa na fizycznym iPhonie i Androidzie | 16–24 h |
| 7. Gotowość produkcyjna | Hosting, pipeline, kopie, przywrócenie, logi, retencja, procedury i przegląd dostępu | Spełniona lista gotowości do pilotażu | 20–32 h |
| 8. Pilotaż i poprawki | Wprowadzenie uczestników, obserwacja, naprawa problemów i ocena wyników | Decyzja o dalszym kierunku na podstawie użycia | 16–24 h pracy + 4 tygodnie obserwacji |

Suma pracy: **172–264 godziny**. Z rezerwą 30%: około **224–344 godzin**.

Przy 10 godzinach pracy tygodniowo oznacza to około 23–35 tygodni pracy; przy 20 godzinach około 12–18 tygodni. Obserwacja pilotażu może częściowo pokrywać się z poprawkami. To nie obietnica terminu: po etapie 1 trzeba ponownie oszacować pozostałe prace.

Pierwszy demonstracyjny proces może powstać po etapie 1. Nie jest jeszcze wersją gotową do przechowywania danych rzeczywistych pacjentów. Wczesny prototyp sprawdzamy na fikcyjnych kontach.

Jeżeli zakres okazuje się zbyt duży, najpierw ograniczamy liczbę ekranów administracyjnych lub odkładamy szablony i rozbudowane filtrowanie. Zachowujemy ochronę dostępu, poprawną historię zaleceń, rzeczywisty zapis wyników i odtwarzanie na telefonach. Taka zmiana wymaga aktualizacji listy MVP.

## 22. Weryfikacja przed oddaniem użytkownikom

### Automatyczne testy najważniejszych reguł

1. Klient nie odczytuje ani nie zmienia danych drugiego klienta po podmianie identyfikatora.
2. Fizjoterapeuta nie odczytuje danych klienta bez przypisania; dane innego gabinetu pozostają niedostępne.
3. Dostęp do filmu wynika z planu klienta, a nie tylko zalogowania lub znajomości identyfikatora.
4. Zmiana ćwiczenia lub szablonu nie zmienia opublikowanego planu i historii treningu.
5. Publikacja oraz zmiana harmonogramu nie tworzą dwóch aktywnych treningów na ten sam dzień.
6. Późny, ponowiony lub równoległy zapis wyniku nie tworzy duplikatu i nie nadpisuje nowszej wersji bez kontroli.
7. Daty i wskaźniki są poprawne na granicy dnia oraz przy zmianie czasu.
8. Trzy główne scenariusze przechodzą od początku do końca: zaproszenie, publikacja planu, realizacja z feedbackiem.

### Próby na rzeczywistych urządzeniach

1. Safari na fizycznym iPhonie oraz Chrome na fizycznym Androidzie.
2. Tryb przeglądarki i uruchomienie po dodaniu do ekranu głównego.
3. Wolniejsze połączenie, przewijanie filmu i wygaśnięcie adresu odtwarzania.
4. Utrata internetu przed zapisem i ponowienie po odzyskaniu połączenia.
5. Zablokowanie ekranu, przejście do innej aplikacji i ponowne otwarcie treningu.
6. Nieprawidłowy format, przerwany upload i odrzucenie zbyt dużego filmu.
7. Wygasłe zaproszenie, reset hasła, wylogowanie i odebranie dostępu.
8. Aktualizacja PWA bez przerwania trwającego treningu i wyświetlenia starego stanu po kolejnym logowaniu.
9. Powiększony tekst, obsługa klawiaturą i najważniejsze widoki z czytnikiem ekranu.
10. Przywrócenie kopii na odseparowanym środowisku i odtworzenie powiązań planów z filmami.

Test w emulatorze nie zastępuje odtwarzania rzeczywistego filmu na prawdziwym telefonie.

## 23. Warunki rozpoczęcia pilotażu

1. Cały proces działa: ćwiczenie, plan, film, wynik i feedback widoczny u opiekuna.
2. Dostęp do cudzych danych i plików jest blokowany oraz przetestowany.
3. Historia zachowuje dokładne wersje zaleceń.
4. Zapisy wyników są odporne na ponowienia i błędy połączenia.
5. Personel ma MFA, a konta i role zostały przejrzane.
6. Odtwarzanie oraz instalacja PWA zostały sprawdzone na iPhonie i Androidzie.
7. Dostarczanie zaproszeń i resetowanie hasła działa na rzeczywistych skrzynkach.
8. Kopie i odtworzenie są sprawdzone, a osoba odpowiedzialna za awarię jest wskazana.
9. Ustalono zasady danych, retencję, dokumenty dla klientów i przeznaczenie produktu.
10. Istnieje kanał zgłoszeń i krótka instrukcja dla obu ról.
11. Wyceniono utrzymanie i ustalono budżet.
12. Nie ma znanych błędów powodujących ujawnienie danych, utratę zapisu ani wyświetlenie niewłaściwego planu.

Do pierwszej próby wybieramy kilka osób i rozszerzamy grupę po sprawdzeniu działania. Problemy naprawiamy według wpływu na dostęp do zaleceń, ochronę danych i możliwość ukończenia podstawowego procesu.

## 24. Najważniejsze ryzyka i sposób ich ograniczenia

| Ryzyko | Działanie |
| :-- | :-- |
| Za duży zakres na początek | Jedno MVP, jeden gabinet, konkretna lista funkcji odłożonych |
| Nauka zbyt wielu technologii jednocześnie | Vue i .NET; PWA przed aplikacjami sklepowymi |
| Film z telefonu nie działa u klienta | Próba z rzeczywistym plikiem w pierwszym etapie i zamknięcie decyzji o formacie |
| Klient nie rozumie parametrów | Próby na kilku osobach, jasne jednostki i instrukcje |
| Za dużo klikania po treningu | Jedno działanie dla pełnej realizacji i opcjonalny feedback |
| Zmieniona treść historii | Niezmienne wersje i brak nadpisywania używanych filmów |
| Ujawnienie danych przez błędny dostęp | Sprawdzenie uprawnień do rekordów i testy z kilkoma kontami |
| Błędne wrażenie stałego nadzoru | Jasne zasady przeglądania feedbacku i kontakt do gabinetu |
| Wzrost kosztów filmów | Kompresja, limity, monitoring transferu i kontrola kosztów |
| Uzależnienie od pamięci jednej osoby | Repozytorium, instrukcja wdrożenia, procedura kopii i ten dokument |

## 25. Decyzje do zatwierdzenia

| Pytanie | Rekomendowany wariant początkowy | Co zmienia inna decyzja |
| :-- | :-- | :-- |
| PWA czy od razu sklepy? | PWA | Dodatkowe budowanie, testy, logowanie i publikacja |
| Jeden gabinet czy produkt dla wielu firm? | Jeden gabinet, dane przygotowane do izolacji | Onboarding firm, rozliczenia i szersze zarządzanie uprawnieniami |
| Dorośli czy także dzieci? | Tylko dorośli | Role opiekunów i dodatkowe ustalenia organizacyjne oraz prawne |
| Jaki feedback? | Realizacja, trudność, opcjonalny ból i komentarz | Nowe formularze i większy zakres danych |
| Czy klient nagrywa siebie? | Nie w MVP | Dodatkowe dane, transfer, zgody i przegląd materiałów |
| Czy fizjoterapeuta przygotuje zgodny MP4? | Tak, o ile próba potwierdzi wygodę | Własny proces transkodowania i dodatkowy czas wdrożenia |
| Czy potrzebne jest offline? | Nie w MVP | Trwały zapis lokalny, ochrona danych i synchronizacja |
| Czy są potrzebne przypomnienia? | Po pilotażu | Preferencje klienta, harmonogram wysyłek i obsługa kanałów |
| Czy przechowujemy dokumentację medyczną? | Nie zakładamy zastępowania systemu gabinetowego | Osobna analiza zakresu i obowiązków |
| Jaki budżet i czas tygodniowo? | Ustalić przed wyborem usług | Dobór hostingu i realny harmonogram |

Domyślne propozycje umożliwiają rozpoczęcie prototypu bez rozstrzygania całego przyszłego produktu. Decyzje dotyczące rzeczywistych danych i przeznaczenia muszą być zamknięte przed pilotażem.

## 26. Od czego zacząć praktycznie

1. Omówić dokument z jednym fizjoterapeutą i skrócić zakres, jeżeli nie rozwiązuje jego codziennego problemu.
2. Przygotować 5 przykładowych ćwiczeń i 2 nagrania z telefonu, na którym będą powstawać materiały.
3. Narysować trzy widoki: dzisiejszy trening klienta, ćwiczenie z filmem i edytor planu fizjoterapeuty.
4. Założyć repozytorium i zapisać dokument w `docs/product-plan.md`.
5. Zbudować najprostszy przekrój z etapu 1 i od razu sprawdzić go na telefonie.
6. Następnie zamknąć konta i uprawnienia, zanim projekt zacznie obsługiwać rzeczywiste dane.

### Pierwsze zadanie programistyczne

Na fikcyjnych danych uruchomić jeden backend ASP.NET Core, jedną bazę PostgreSQL i jeden interfejs Vue. Testowy klient otwiera trening zawierający jedno ćwiczenie, odtwarza film, oznacza wykonanie całości i zapisuje komentarz. Testowy fizjoterapeuta odczytuje wynik. Ograniczony dostęp testowy nie jest publicznie wdrażany jako gotowe logowanie.

Warunek ukończenia: po odświeżeniu strony zapis nadal istnieje w bazie, a proces działa na iPhonie i Androidzie. Dopiero wtedy rozwijamy bibliotekę, edytor planu i kolejne ekrany.

### Czego uczyć się w tej kolejności

1. Responsywnego interfejsu Vue i odtwarzania wideo w przeglądarce telefonu.
2. ASP.NET Core Identity, sesji, CSRF oraz uprawnień do danych konkretnej osoby.
3. Uploadu do prywatnego magazynu i czasowego udostępniania filmów.
4. Modelowania planów, historii i ponawialnych zapisów.
5. PWA, service workera i zachowania przy utracie połączenia.
6. Produkcyjnego wdrożenia, kopii i monitoringu.
7. Capacitor i publikacji mobilnej dopiero po potwierdzeniu potrzeby.

## 27. Aktualizowanie dokumentu

Po każdym etapie należy zapisać podjęte decyzje, zmienić status funkcji i skorygować prognozę czasu. Nowa funkcja otrzymuje cel, zakres, kryterium ukończenia i miejsce w planie. Zmiana dotycząca danych, harmonogramu lub przeznaczenia wymaga także aktualizacji powiązanych zasad.

## 28. Źródła i dokumentacja

Weryfikacja źródeł: 15.10.2026. Źródła opisują możliwości platform i wymagania ogólne. Wybór zakresu, model danych, harmonogram pracy oraz cele pilotażu są propozycjami projektowymi tego dokumentu.

1. **[S1] Apple:** [Turn a website into an app in Safari on iPhone](https://support.apple.com/guide/iphone/open-as-web-app-iphea86e5236/ios).
2. **[S2] Google web.dev:** [PWA installation](https://web.dev/learn/pwa/installation).
3. **[S3] Capacitor:** [Installing Capacitor](https://capacitorjs.com/docs/getting-started).
4. **[S4] Microsoft:** [.NET support policy](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core).
5. **[S5] Microsoft:** [Use Identity to secure a Web API backend for SPAs](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-10.0).
6. **[S6] Microsoft:** [Security recommendations for Blob Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/security-recommendations).
7. **[S7] Microsoft:** [Prevent Cross-Site Request Forgery attacks in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/anti-request-forgery?view=aspnetcore-10.0).
8. **[S8] Komisja Europejska:** [Legal grounds for processing data](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en).
9. **[S9] Europejska Rada Ochrony Danych:** [Process personal data lawfully](https://www.edpb.europa.eu/sme/be-compliant/process-personal-data-lawfully_en).
10. **[S10] Komisja Europejska:** [Principles of personal data processing under the GDPR](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/principles-gdpr_en).
11. **[S11] Komisja Europejska, MDCG 2019-11 rev.1, czerwiec 2025:** [Qualification and classification of software](https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en).
12. **[S12] Capacitor:** [Environment setup](https://capacitorjs.com/docs/getting-started/environment-setup).
13. **[S13] Microsoft Azure:** [Pricing calculator](https://azure.microsoft.com/en-us/pricing/calculator/).
