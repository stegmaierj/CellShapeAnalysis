  function fboth(f,varargin)
% function fboth(f,varargin)
%
% plottet auf Bildschirm und in File f (nur für f~=1)
% wenn f Vektor ist, wird 2. Element als Anzeige Detailinfos interpretiert = 0: kein Bildschirmplot, = 1 Bildschirmplot
% 
% wenn nur 1 Parameter dann anzeigen!
%
% Die Funktion fboth ist Teil der MATLAB-Toolbox Gait-CAD. 
% Copyright (C) 2007  [Ralf Mikut, Tobias Loose, Ole Burmeister, Sebastian Braun, Markus Reischl]


% Letztes Änderungsdatum: 10-May-2007 17:50:28
% 
% Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License,
% wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, 
% entweder gemäß Version 2 der Lizenz oder jeder späteren Version.
% 
% Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, dass es Ihnen von Nutzen sein wird,
% aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder 
% der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK.
% Details finden Sie in der GNU General Public License.
% 
% Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben.
% Falls nicht, schreiben Sie an die Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA.
% 
% Weitere Erläuterungen zu Gait-CAD finden Sie in der beiliegenden Dokumentation oder im folgenden Konferenzbeitrag:
% 
% MIKUT, R.; BURMEISTER, O.; REISCHL, M.; LOOSE, T.:  Die MATLAB-Toolbox Gait-CAD. 
% In:  Proc., 16. Workshop Computational Intelligence, S. 114-124, Universitätsverlag Karlsruhe, 2006
% Online verfügbar unter: http://www.iai.fzk.de/projekte/biosignal/public_html/gaitcad.pdf
% 
% Bitte zitieren Sie diesen Beitrag, wenn Sie Gait-CAD für Ihre wissenschaftliche Tätigkeit verwenden.

if (length(f)==1) 
   f(2)=1;
end; 

%Bildschirmplot, wenn Anzeigeparameter gesetzt
if f(2)
   fprintf(1,varargin{:});
end;

%Fileplot, wenn File
if f(1)~=1 
   fprintf(f(1),varargin{:});
end;