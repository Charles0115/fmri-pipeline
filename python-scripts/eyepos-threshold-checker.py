import pandas as pd


def generate_eyepos_magnitude_censor_1Dfile(datafile, output, start_trial, end_trial, method, mean_threshold=None,
                                            std_dev_threshold=None, fixation=None, percent_threshold=None):
    df = pd.read_csv(datafile)
    df['timestamp'] = df.index

    eye_pos_mag_list = ['timestamp']
    for trial in range(start_trial, end_trial+1):
        eye_pos_mag_list.append("eye_pos{:02d}_magnitude".format(trial))
    eye_pos_data = df[eye_pos_mag_list]

    output_list = []
    for trial_index in range(start_trial, end_trial+1):
        eye_pos_magnitude = eye_pos_data.iloc[0:int(
            eye_pos_data.loc[eye_pos_data['eye_pos{:02d}_magnitude'.format(trial_index)].last_valid_index()][
                'timestamp']) + 1][['timestamp', 'eye_pos{:02d}_magnitude'.format(trial_index)]]

        def chunk_list(data, chunk_size):
            """Yields successive n-sized chunks from data."""
            for i in range(0, len(data), chunk_size):
                yield data[i:i + chunk_size]

        chunks = list(chunk_list(eye_pos_magnitude, 1250))

        result = []
        if method == 'mean':
            if mean_threshold is not None and std_dev_threshold is not None:
                for chunk in chunks:
                    mean = chunk['eye_pos{:02d}_magnitude'.format(trial_index)].mean()
                    std_dev = chunk['eye_pos{:02d}_magnitude'.format(trial_index)].std()
                    if (mean < mean_threshold) and (std_dev < std_dev_threshold):
                        result.append(1)
                    else:
                        result.append(0)
            else:
                raise Exception("mean_threshold or std_dev_threshold cannot be empty!")
        elif method == 'percentage':
            if fixation is not None and percent_threshold is not None:
                for chunk in chunks:
                    good_magnitude = chunk[chunk['eye_pos{:02d}_magnitude'.format(trial_index)] < fixation]
                    good_rate = len(good_magnitude.index) / 1250

                    if good_rate > percent_threshold:
                        result.append(1)
                    else:
                        result.append(0)
            else:
                raise Exception("Fixation or percent_threshold cannot be empty!")
        else:
            raise Exception("Invalid method!")

        output_list.append(result)

    with open(output, "w") as f:
        for l in output_list:
            f.write("\n".join(map(str, l)))
            f.write("\n")


if __name__ == '__main__':
    generate_eyepos_magnitude_censor_1Dfile('250605_PIP_25TD0605-run01-eye_pos.csv', '250605_PIP_25TD0605-run01-eye_pos.1D', 1, 16, 'percentage',
                                            fixation=1.0, percent_threshold=0.8)
