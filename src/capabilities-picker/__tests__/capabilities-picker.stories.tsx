import React, {useEffect, useState} from 'react';
import '@patternfly/react-core/dist/styles/base.css';
import {storiesOf} from '@storybook/react';
import {action} from "@storybook/addon-actions";
import {mockLauncherClient, propsWithValuesMapper} from 'launcher-client';
import {capabilityToItem, defaultCapabilitiesPickerValue} from "../capabilities-adapter";
import {CapabilitiesPicker} from "../capabilities-picker";
import {FormPanel} from "../../form-panel/form-panel";


const client = mockLauncherClient({creatorUrl: 'efe', launcherURL: 'eqg'});


function LoadData<T>(props: { loader: Promise<T>, default: T, children: any }) {
  const [data, setData] = useState<T>(props.default);

  useEffect(() => {
    props.loader.then((d) => setData(d));
  });

  return props.children(data);

};

storiesOf('CapabilitiesPicker', module)
  .add('default', () => {
    const itemsLoader = client.capabilities().then(c => {
      return client.enums().then(e => {
        return c.map(propsWithValuesMapper(e))
          .map(capabilityToItem)
          .filter(c => c.category !== 'frontend');
      });
    });

    return (
      <LoadData loader={itemsLoader} default={[]}>
        {items => (
          <FormPanel value={defaultCapabilitiesPickerValue} onSave={action('save')}
                     onCancel={action('cancel')}>
            {
              (inputProps) => (<CapabilitiesPicker {...inputProps} items={items}/>)
            }
          </FormPanel>
        )}
      </LoadData>
    );
  });