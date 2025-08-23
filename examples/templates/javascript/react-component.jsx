import React from 'react';
import PropTypes from 'prop-types';

/**
 * {{component}} component
 * {{description}}
 * @author {{author}}
 */
const {{component}} = ({ {{props}} }) => {
  return (
    <div className="{{component_class}}">
      <h1>{{component}}</h1>
      {/* Component content */}
    </div>
  );
};

{{component}}.propTypes = {
  {{prop_types}}
};

{{component}}.defaultProps = {
  {{default_props}}
};

export default {{component}};
