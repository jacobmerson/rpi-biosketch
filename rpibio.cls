\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rpibio}[2026/03/05 RPI biosketch class]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass{article}

\RequirePackage{etaremune}
\RequirePackage{titlesec}
\RequirePackage{fancyhdr}
\RequirePackage{longtable}
\RequirePackage[dvipsnames]{xcolor}
\RequirePackage{hyperref}
\hypersetup{
    colorlinks=true,
    urlcolor=Black,
    linkcolor=Blue,
    filecolor=Blue,
}

\titlespacing\section{0pt}{12pt plus 4pt minus 2pt}{3pt plus 2pt minus 2pt}

\setcounter{secnumdepth}{4}
\setcounter{tocdepth}{4}

\titleformat{\section}
{\large \bfseries  \color{black}}{\thesection}{.5em}{}
\renewcommand\thesection{\Roman{section}.}

\titleformat{\subsection}
{\large \bfseries  \color{black}}{\thesubsection}{.5em}{}
\renewcommand\thesubsection{\Alph{subsection}.}
%\titlespacing*{\subsection}{2em}{0pt}{0.5\baselineskip}

\titleformat{\subsubsection}
{\large \bfseries  \color{Black}}{\thesubsubsection}{.5em}{}
\renewcommand\thesubsubsection{\arabic{subsubsection}.}

\titleclass{\subsubsubsection}{straight}[\subsubsection]
\newcounter{subsubsubsection}[subsubsection]
\renewcommand\thesubsubsubsection{\thesubsubsection.\arabic{subsubsubsection}}
\titleformat{\subsubsubsection}
  {\normalfont\normalsize\bfseries}{\thesubsubsubsection}{.5em}{}
\titlespacing*{\subsubsubsection}
  {0pt}{3.25ex plus 1ex minus .2ex}{1.5ex plus .2ex}
\renewcommand\thesubsubsubsection{\alph{subsubsubsection}.}

% this code block should set set up the level of the heading for hyperref / TOC
\makeatletter
\providecommand*{\toclevel@subsubsubsection}{4}
\providecommand*{\l@subsubsubsection}{\@dottedtocline{4}{7em}{4em}}
\@namedef{Hy@toclevel@subsubsubsection}{4}% instead of \Hy@newcommand...
\makeatother

\RequirePackage[margin=3cm]{geometry}

% Setting the fonts
\RequirePackage{fontspec}
\setmainfont{Times New Roman}

% Set line spacing
\renewcommand{\baselinestretch}{1.1}

\RequirePackage[multiple]{footmisc}

% Used for formatting funding amounts in biblatex with num
\RequirePackage{siunitx}
\sisetup{
  group-separator = {,},
  group-minimum-digits = 4
}

\RequirePackage{etoolbox}


\RequirePackage[
  backend=biber,
  style=RPIBiosketch,
  defernumbers=true,
  sorting=ymdnt,
  eprint=false,
  datamodel=RPIBiosketch,
  maxbibnames=99
]{biblatex}

% similar to ydnt but include rest of date
\DeclareSortingTemplate{ymdnt}{%
  \sort{\field{presort}}%
  \sort[final]{\field{sortkey}}%
  \sort[direction=descending]{%
    %\field[strside=left,strwidth=4]{sortyear}%
    \field[strside=left,strwidth=4]{year}%
    \literal{0000}%
  }%
  \sort[direction=descending]{%
    %\field[strside=left,strwidth=2]{sortmonth}%
    \field[strside=left,strwidth=2]{month}%
    \literal{00}%
  }%
  \sort[direction=descending]{%
    %\field[strside=left,strwidth=2]{sortday}%
    \field[strside=left,strwidth=2]{day}%
    \literal{00}%
  }%
  \sort{\field{sortname}}%
  \sort{\field{sorttitle}}%
}

\providecommand{\bibliofont}{}
\addbibresource{sections/publications.bib}
\addbibresource{sections/grants.bib}

%% ============================================================
%% REVERSE NUMBERING SYSTEM
%% ============================================================
%% Goal: bibliography entries are numbered from N down to 1
%% (most recent = highest number), instead of the default 1..N.
%%
%% How it works (two-pass round-trip via the .aux file):
%%   Pass 1 (first lualatex run):
%%     - Each bibliography list gets a unique ID (biblistid counter).
%%     - As items are printed, their raw position and list ID are written
%%       to the .aux file using \write\@auxout.
%%     - The total count for each list is also written to the .aux file.
%%   Pass 2 (subsequent lualatex run):
%%     - The .aux data is available, so the reversed label can be computed:
%%       reversed_label = total_count + 1 - raw_position
%%     - Inline \cite commands use the saved prefix/position from the
%%       first bibliography that printed the entry.
%%
%% Reference: https://tex.stackexchange.com/questions/21401/biblatex-reverse-numbering-i-e-count-down
%% ============================================================
%\makeatletter
\makeatletter

% 1. Create a global counter to distinguish between different bibliographies
\newcounter{biblistid}
\setcounter{biblistid}{0}

% 2. Create a counter to track items in the CURRENT list
\newcounter{localbibcount}

% 3. Flag to distinguish bibliography context from inline \cite
\newif\ifbbx@inbib

% 4. When a bibliography starts:
%    - Increment the list ID (so this list has a unique name)
%    - Reset the local item counter
%    - Set the in-bibliography flag
\AtBeginBibliography{%
  \stepcounter{biblistid}%
  \setcounter{localbibcount}{0}%
  \bbx@inbibtrue
}

% 5. Count every item printed.
%    Only the FIRST bibliography that prints an entry is recorded, so that
%    \cite prefers conference proceedings over lectures.
%    We pre-expand the entry key with \edef to avoid fragile nested \csname
%    inside \write and \ifcsundef.
\AtEveryBibitem{%
  \stepcounter{localbibcount}%
  \edef\bbx@curkey{\csname abx@field@entrykey\endcsname}%
  \ifcsundef{bbx@mapped@\bbx@curkey}{%
    \csgdef{bbx@mapped@\bbx@curkey}{}%
    % Save list ID and raw position in aux file (numbers only — safe to \write)
    \immediate\write\@auxout{%
      \string\csgdef{biblistof:\bbx@curkey}{\number\value{biblistid}}%
    }%
    \immediate\write\@auxout{%
      \string\csgdef{bibrawnum:\bbx@curkey}{\number\value{localbibcount}}%
    }%
    % Save the label prefix at runtime (avoids \write expansion issues)
    \ifcsundef{abx@field@labelprefix}{}{%
      \expandafter\xdef\csname bbx@savedprefix@\bbx@curkey\endcsname{%
        \csname abx@field@labelprefix\endcsname}%
    }%
  }{}%
}

% 6. Save the total for THIS specific list ID and clear the in-bib flag
\appto\blx@endbibliography{%
  \immediate\write\@auxout{%
    \string\csgdef{totalcount:\number\value{biblistid}}{\number\value{localbibcount}}%
  }%
  \bbx@inbibfalse
}

% 7. Override the label prefix for inline citations so it matches
%    the first bibliography (e.g. C instead of CL).
\AtEveryCitekey{%
  \ifbbx@inbib\else
    \edef\bbx@curkey{\csname abx@field@entrykey\endcsname}%
    \ifcsundef{bbx@savedprefix@\bbx@curkey}{}{%
      \edef\abx@field@labelprefix{%
        \csuse{bbx@savedprefix@\bbx@curkey}}%
    }%
  \fi
}

% 8. The Label Format
%    Inside a bibliography: use \value{biblistid} directly (always correct,
%    even when an entry appears in multiple printed bibliographies).
%    In an inline \cite: use the saved raw position and list ID from the
%    first bibliography that printed the entry.
\DeclareFieldFormat{labelnumber}{\mkbibdesc{#1}}
\newrobustcmd*{\mkbibdesc}[1]{%
  \ifbbx@inbib
    % Inside bibliography: current biblistid is always right
    \ifcsundef{totalcount:\number\value{biblistid}}
      {#1}%
      {\number\numexpr\csuse{totalcount:\number\value{biblistid}} + 1 - #1\relax}%
  \else
    % Inline citation: use saved raw number from the first bibliography
    \edef\bbx@curkey{\csname abx@field@entrykey\endcsname}%
    \ifcsundef{bibrawnum:\bbx@curkey}
      {#1}% first run fallback
      {\ifcsundef{totalcount:\csuse{biblistof:\bbx@curkey}}
        {#1}%
        {\number\numexpr\csuse{totalcount:\csuse{biblistof:\bbx@curkey}} + 1 - \csuse{bibrawnum:\bbx@curkey}\relax}%
      }%
  \fi
}
\makeatother
%%-- End of Reverse Numbering --%%
% TODO consider refactoring to use \defbibcheck instead of \defbibfilter since that can be used
% for both the printing and counters

%% ============================================================
%% PUBLICATION AND PROPOSAL COUNTERS
%% ============================================================
%% These counters accumulate totals at data-input time (before any
%% bibliography is printed) so the summary tables are available at
%% the top of the Publications and Grants sections.
%%
%% Publication counters (peerreviewedjournalcount, peerreviewedconferencecount):
%%   Incremented via \AtDataInput for entries matching keyword combinations.
%%   \bbx@markpublication guards against double-counting the same entry.
%%
%% Proposal counters (funded/pending proposalcount, totalamount, myamount):
%%   Incremented via \AtDataInput[proposal] for @proposal entries.
%%   \bbx@markproposal guards against double-counting.
%%   In-kind proposals (keyword=inkind) are counted separately and their
%%   monetary amounts are excluded from the totals.
%% ============================================================
\newcounter{bookcount}
\newcounter{bookchaptercount}
\newcounter{peerreviewedjournalcount}
\newcounter{peerreviewedconferencecount}
\makeatletter
\newcommand{\bbx@markpublication}[2]{%
  \ifcsundef{bbx@pub@#1@#2}{%
    \expandafter\gdef\csname bbx@pub@#1@#2\endcsname{}%
    \stepcounter{#1}%
  }{}%
}
\AtDataInput{%
  \edef\bbx@pubkey{\thefield{entrykey}}%
  %\ifentrytype{book}{\bbx@markpublication{bookcount}{\bbx@pubkey}}{}%
  %\ifentrytype{collection}{\bbx@markpublication{bookcount}{\bbx@pubkey}}{}%
  %\ifentrytype{inbook}{\bbx@markpublication{bookchaptercount}{\bbx@pubkey}}{}%
  %\ifentrytype{incollection}{\bbx@markpublication{bookchaptercount}{\bbx@pubkey}}{}%
  \ifboolexpr{ test {\ifkeyword{journal}} and test {\ifkeyword{published}} }{%
    \bbx@markpublication{peerreviewedjournalcount}{\bbx@pubkey}}{}%
  \ifboolexpr{ test {\ifkeyword{conference}} and test {\ifkeyword{peerreview}} }{%
    \bbx@markpublication{peerreviewedconferencecount}{\bbx@pubkey}}{}%
}
\makeatother


%% counters for article types

\newcommand{\printarticlesummary}{%
\begin{center}
  \begin{tabular}{|lc|}
    \hline
    \textbf{Publication Category} & \textbf{Count} \\
    \hline\hline
    %Books & \arabic{bookcount} \\
    %Book Chapters & \arabic{bookchaptercount} \\
    Peer-reviewed Journal & \arabic{peerreviewedjournalcount} \\
    Peer-reviewed Conference & \arabic{peerreviewedconferencecount} \\
    \hline
  \end{tabular}
\end{center}
}
% end counters for article types

% counters for funding summary
\newcounter{fundedproposalcount}
\newcounter{fundedtotalamount}
\newcounter{fundedtotalmyamount}
\newcounter{fundedinkindproposalcount}
\newcounter{pendingproposalcount}
\newcounter{pendinginkindproposalcount}
\newcounter{pendingtotalamount}
\newcounter{pendingtotalmyamount}

\makeatletter
    \newcommand{\bbx@markproposal}[2]{%
      \ifcsundef{bbx@#1@counted@#2}{%
        \expandafter\gdef\csname bbx@#1@counted@#2\endcsname{}%
        % don't count in-kind support
        \ifkeyword{inkind}{
          \stepcounter{#1inkindproposalcount}%
        }
        {
        \stepcounter{#1proposalcount}%
        \iffieldundef{amount}{}{\addtocounter{#1totalamount}{\thefield{amount}}}%
        \iffieldundef{myamount}{}{\addtocounter{#1totalmyamount}{\thefield{myamount}}}%
        }%
      }{}%
    }
    \AtDataInput[proposal]{%
      \edef\bbx@currentkey{\thefield{entrykey}}%
      \ifkeyword{funded}{\bbx@markproposal{funded}{\bbx@currentkey}}{}%
      \ifkeyword{pending}{\bbx@markproposal{pending}{\bbx@currentkey}}{}%
    }
\makeatother
\newcommand{\printfundedsummary}{%
\begin{center}
  \begin{tabular}{|cccc|}
    \hline
    \textbf{Proposal Status} & \textbf{Count} & \textbf{Total Amount} & \textbf{My Share} \\
    \hline\hline
    Funded (monetary) & \arabic{fundedproposalcount} & \printdollars{\arabic{fundedtotalamount}} & \printdollars{\arabic{fundedtotalmyamount}} \\
    Pending (monetary) & \arabic{pendingproposalcount} & \printdollars{\arabic{pendingtotalamount}} & \printdollars{\arabic{pendingtotalmyamount}} \\
    Funded (in-kind) & \arabic{fundedinkindproposalcount} & - & - \\
    Pending (in-kind) & \arabic{pendinginkindproposalcount} & - & - \\
    \hline
  \end{tabular}
\end{center}
}
%% end of counters for funding summary

\defbibfilter{submitted_journals}{%
  keyword=journal and
  keyword=submitted
}

\defbibfilter{published_journals}{%
  keyword=journal and
  keyword=published
}

\defbibfilter{refereed_conferences}{%
  keyword=peerreview and keyword=conference
}

\defbibfilter{abstracts_conferences}{%
  keyword=conference and not keyword=peerreview
}

\defbibfilter{invited_lectures}{
  keyword=invited
}
\defbibfilter{contributed_lectures} {
  keyword=contributed
}
\defbibfilter{funded_proposal}{
  type=proposal and
  keyword=funded
}
\defbibfilter{unfunded_proposal}{
  type=proposal and
  keyword=unfunded
}
\defbibfilter{pending_proposal}{
  type=proposal and
  keyword=pending
}

%% PhD student milestone timeline table
%% Usage: \phdtimeline{Start}{DQE}{Candidacy}{Defense}
\newcommand{\phdtimeline}[4]{%
  \begin{longtable}{|p{.17\textwidth} p{.17\textwidth} p{.17\textwidth} p{.3\textwidth} |}
  \hline
  Start & DQE & Candidacy & Defense\\
  \hline\hline
  #1 & #2 & #3 & #4 \\
  \hline
  \end{longtable}\vspace{-.2in}%
}

%% Date range helpers for consistent formatting
%% Usage: \daterange{Start}{End}  e.g. \daterange{2015}{2021}
%% Usage: \dateto{Start}          e.g. \dateto{Jul.\ 2023}
\newcommand{\daterange}[2]{#1\,--\,#2}
\newcommand{\dateto}[1]{#1\,--\,present}

%% Generic student entry: name, degree/major, pre-formatted dates, project title
%% Use \dateto{start} or \daterange{start}{end} for the dates argument.
\newcommand{\studentitem}[4]{%
  \item \textbf{#1} (#2) \hfill #3\\
  Project: \emph{#4}%
}
\newcommand{\bsstudent}[4]{\studentitem{#1}{#2}{#3}{#4}}
\newcommand{\msstudent}[4]{\studentitem{#1}{#2}{#3}{#4}}

%% Full PhD student entry: name, major (empty=omit), project, start, DQE, candidacy, defense
\newcommand{\phdstudent}[7]{%
  \item \textbf{#1}\ifblank{#2}{}{ (#2)}\\
  Project: \emph{#3}\vspace{-.1 in}
  \phdtimeline{#4}{#5}{#6}{#7}%
}

%% Postdoc entry: name, start date, PhD institution, PhD completion date
\newcommand{\postdocentry}[4]{%
  \item \textbf{#1} \hfill \dateto{#2}\\
  Ph.D.\ from #3 \hfill #4%
}

%% Committee member: name, dept abbr, advisor, milestone, date
\newcommand{\committeeentry}[5]{%
  \item \textbf{#1} (#2) -- Advisor: #3\\
  #4 \hfill #5%
}

%% Section status divider used in Students_MS.tex (and any future status-split lists)
\newcommand{\statusheader}[1]{\vspace{.15in}\noindent\underline{\large\textbf{#1}}}

%% command for table of contributions
\newcommand{\contributionstable}{
\begin{center}
\begin{tabular}{|l|l|}
\hline
\textbf{Sym.} & \textbf{Description} \\ \hline\hline 
*& equal contributions \\
\S& corresponding author(s) \\
$\dag$ &bachelors student in my lab \\
$\ddag$&masters student in my lab \\
\#& Ph.D. student in my lab \\
+& Postdoc in my lab \\
\textbf{boldface} &presenter\\
\hline
\end{tabular}
\end{center}
}

\RequirePackage{framed}

% Metadata defaults — override all of these in metadata.tex
\newcommand{\biosketchname}{Jacob S. Merson}
\newcommand{\authordept}{}
\newcommand{\authorschool}{}
\newcommand{\authorrank}{}
\newcommand{\authorinstitution}{Rensselaer Polytechnic Institute}

\newcommand{\makebiosketchtitle}{%
\begin{center}
{\large BIOGRAPHICAL SKETCH AND PROFESSIONAL ACTIVITIES\\
\MakeUppercase{\authorinstitution}}
\end{center}
\vspace{.05 in}
}

%\setlength{\headheight}{22pt}
\AtBeginDocument{%
  \lhead{\LARGE \textbf{\biosketchname}}%
  \rhead{\Large  \today}%
}
