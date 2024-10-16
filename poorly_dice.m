function [edges, probabilities] = poorly_dice(dice_inputs, plot_type, varargin)
    % Simulazione del lancio di dadi o costanti
    % dice_inputs: cell array di stringhe in formato XdY o costante
    % plot_type: tipo di plot ('normal', 'at least', 'at most')
    % num_rolls: numero totale di lanci
    % percentile: vettore di percentuali da plottare come linee verticali
    % probability: vettore di probabilità da plottare come linee orizzontali

    if (nargin) < 3
      num_rolls = 5000;
      percentile = 55;
      probability = 50;
    elseif (nargin) >= 3 && (nargin) < 4
      num_rolls = varargin{1};
      percentile = 55;
      probability = 50;
    elseif (nargin) >= 4 && (nargin) < 5
      num_rolls = varargin{1};
      percentile = varargin{2};
      probability = 50;
    else
      num_rolls = varargin{1};
      percentile = varargin{2};
      probability = varargin{3};
    end

    % Inizializza un array per i risultati totali
    total_results = zeros(1, num_rolls);

    % Analizza ogni input dei dadi e sommali o sottrai i risultati
    for i = 1:length(dice_inputs)
        results = analyze_input(dice_inputs{i}, num_rolls);
        total_results = total_results + results; % Somma o sottrai i risultati dei dadi
    end

    % Calcola media, mediana, deviazione standard, massimo e minimo
    mean_value = mean(total_results);
    median_value = median(total_results);
    std_dev = std(total_results);
    max_value = max(total_results);
    min_value = min(total_results);

    % Stampa i valori statistici a video
    fprintf('Statistiche della distribuzione:\n');
    fprintf('Media: %.2f\n', mean_value);
    fprintf('Mediana: %.2f\n', median_value);
    fprintf('Deviazione Standard: %.2f\n', std_dev);
    fprintf('Valore massimo: %.2f\n', max_value);
    fprintf('Valore minimo: %.2f\n', min_value);

    % Calcola l'istogramma
    edges = min(total_results):max(total_results);
    counts = zeros(size(edges));

    % Conta i risultati
    for i = 1:num_rolls
        counts(total_results(i) - min(total_results) + 1) = counts(total_results(i) - min(total_results) + 1) + 1;
    end

    % Calcola le probabilità
    probabilities = (counts / num_rolls);

    % Imposta il titolo per il grafico
    title_text = sprintf('Distribuzione dei Risultati (%s)', strjoin(dice_inputs, ' + '));
    title_text = strrep (title_text, '+ +', '+ ');
    title_text = strrep (title_text, '+ -', '- ');


    % Gestisci il tipo di plot
    figure;
    hold on;

    switch lower(plot_type)
        case 'normal'
            % Plot della distribuzione normale
            bar(edges, probabilities, 'FaceColor', [0.5 0.5 0.5]);
            title(title_text, 'FontSize', 14);
            xlabel('Somma dei Dadi');
            ylabel('Probabilità');
            max_prob = max(probabilities); % Calcola max_prob per il caso 'normal';

        case 'at least'
            % Calcola la probabilità cumulativa "at least"
            cumulative_prob = zeros(size(probabilities));
            cumulative_prob(end) = probabilities(end);
            for i = length(probabilities)-1:-1:1
                cumulative_prob(i) = cumulative_prob(i+1) + probabilities(i);
            end

            % Plot della distribuzione "at least"
            bar(edges, cumulative_prob, 'FaceColor', [0.5 0.5 0.5]);
            title(title_text, 'FontSize', 14);
            xlabel('Somma dei Dadi');
            ylabel('Probabilità "At Least"');
            max_prob = max(cumulative_prob); % Calcola max_prob per il caso 'at least';
            probabilities = cumulative_prob;

        case 'at most'
            % Calcola la probabilità cumulativa "at most"
            cumulative_prob = zeros(size(probabilities));
            cumulative_prob(1) = probabilities(1);
            for i = 2:length(probabilities)
                cumulative_prob(i) = cumulative_prob(i-1) + probabilities(i);
            end

            % Plot della distribuzione "at most"
            bar(edges, cumulative_prob, 'FaceColor', [0.5 0.5 0.5]);
            title(title_text, 'FontSize', 14);
            xlabel('Somma dei Dadi');
            ylabel('Probabilità "At Most"');
            max_prob = max(cumulative_prob); % Calcola max_prob per il caso 'at most';
            probabilities = cumulative_prob;

        otherwise
            error('Tipo di plot non valido. Usa "normal", "at least" o "at most".');
    end

    % Aggiungi linee verticali per i percentili
    plot_percentiles(percentile, total_results, counts, edges, num_rolls);

    % Aggiungi linee orizzontali per i valori di probabilità
    plot_probabilities(probability, max_prob, edges);

    % Crea il box per la figura
    set(gca, 'box', 'on','xtick',min(edges):1:max(edges));
    xlim([min(edges)-1 max(edges)+1])
    % Imposta i tick dell'asse y in percentuale
    if ~isequal(lower(plot_type),'normal')
        yticks(0:0.1:1);
        y_tick_labels = arrayfun(@(x) sprintf('%.0f%%', x * 100), yticks, 'UniformOutput', false); % Crea le etichette in percentuale
        yticks(yticks); % Imposta i tick dell'asse y
        set(gca, 'YTickLabel', y_tick_labels); % Imposta le etichette personalizzate
    else
        ylim([0 max_prob + 0.22*max_prob])
    end
    hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Funzione per plottare i percentili
    function plot_percentiles(percentile, total_results, counts, edges, num_rolls)
        yLimit = ylim;
        for k = 1:length(percentile)
            perc_value = prctile(total_results, percentile(k));
            plot([perc_value, perc_value], yLimit, 'b--', 'LineWidth', 1.5);
            text(perc_value, yLimit(2) * 0.85, sprintf('%.0f-th', percentile(k)), ...
                 'HorizontalAlignment', 'left', 'FontSize', 12, 'BackgroundColor', 'white', 'rotation', 90);
        end
    end

    % Funzione per plottare le probabilità
    function plot_probabilities(probability, max_prob, edges)
        xLimit = [min(edges)-1 max(edges) + 1];
        for j = 1:length(probability)
            prob_value = probability(j);
            if prob_value > 1
                prob_value = prob_value / 100;
            end
            normalized_prob_value = prob_value * max_prob;
            plot(xLimit, [normalized_prob_value, normalized_prob_value], 'r--', 'LineWidth', 1.5);
            text(xLimit(2) - 0.05*xLimit(2), normalized_prob_value, sprintf('%.0f%%', prob_value * 100), ...
                 'HorizontalAlignment', 'right', 'FontSize', 12, 'BackgroundColor', 'white');
        end
    end

    % Funzione per analizzare l'input dei dadi o delle costanti
    function results = analyze_input(dice_input, num_rolls)
        % Analizza l'input dei dadi e restituisce i risultati
        multiplier = 1;  % Variabile per determinare somma o sottrazione

        % Controlla se l'input inizia con un segno
        if startsWith(dice_input, '-')
            multiplier = -1;  % Moltiplica per -1 se inizia con '-'
            dice_input = dice_input(2:end);  % Rimuovi il segno dall'input
        elseif startsWith(dice_input, '+')
            dice_input = dice_input(2:end);  % Rimuovi il segno dall'input
        end

        if is_substring(dice_input, 'd')
            % Estrarre il numero di dadi e il numero di facce
            parts = strsplit(dice_input, 'd');
            num_dice = str2double(parts{1});  % Numero di dadi
            num_faces = str2double(parts{2}); % Numero di facce

            % Genera i risultati dei lanci
            rolls = randi(num_faces, num_dice, num_rolls);
            results = sum(rolls, 1);  % Somma i risultati di tutti i dadi
        else
            % Caso di costante, convertila in numero
            constant_value = str2double(dice_input);
            results = constant_value * ones(1, num_rolls);
        end

        % Applica il moltiplicatore per somma o sottrazione
        results = multiplier * results;
    end

    function result = is_substring(str, substr)
        % Controlla se 'substr' è una sottostringa di 'str'
        result = false;
        if length(str) >= length(substr)
            for i = 1:length(str) - length(substr) + 1
                if strcmp(str(i:i+length(substr)-1), substr)
                    result = true;
                    break;
                end
            end
        end
    end

end
